import { LightningElement, api, track } from 'lwc';
// import jsPDFInvoiceTemplate, { OutputType, jsPDF } from "./index.js";
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
import { jsPDF } from "./addImage";

export default class ARC_DownloadPlansSummary2 extends OmniscriptBaseMixin(LightningElement) {

    @api osData;
    @track selectedProducts;

    connectedCallback() {
        this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
        this.selectedProducts = this.osData.selectedProducts;
    }

    handleDownload() {

        var text = 'this this this this this this this this this this this this this this this this';
        function wrapText(text, maxLength) {
            const strWord = text.split(' ');
            let tempWord = '';
            let lineLength = 0;

            return strWord.reduce((acc, word) => {
                lineLength += word.length;
                if(lineLength > maxLength){
                    lineLength = 0;
                    tempWord = word;
                    return `${acc}\n`
                } else {
                    const withTempWord = `${acc} ${tempWord} ${word}`;
                    tempWord = '';
                    return withTempWord;
                }
            }, '');
        }

        const doc = new jsPDF();
        var currentHeight = 20;
        var pdfConfig = {
            headerTextSize: 20,
            labelTextSize: 12,
            fieldTextSize: 10,
            lineHeight: 6,
            subLineHeight: 4,
        };
        
        let table = [];
        let index = 1;
        for (let product of this.selectedProducts) {
            let price = product.currencySymbol+product.Price;
            let prod = [
                index,
                product.Name,
                product.Type__c,
                price
            ]
            index += 1;
            table.push(prod);
        }
        const param = {
            returnJsPDFDocObject: true,
            orientationLandscape: false,
            logo: {
                src: "https://raw.githubusercontent.com/edisonneza/jspdf-invoice-template/demo/images/logo.png",
                width: 53.33, //aspect ratio = width/height
                height: 26.66,
                margin: {
                    top: 0, //negative or positive num, from the current position
                    left: 0 //negative or positive num, from the current position
                }
            },
            invoice: {
                headerBorder: true,
                tableBodyBorder: true,
                header: [
                {
                    title: "#", 
                    style: { 
                    width: 10 
                    } 
                }, 
                { 
                    title: "Product Name",
                    style: {
                    width: 100
                    } 
                }, 
                { 
                    title: "Type",
                    style: {
                    width: 35
                    } 
                }, 
                { title: "Price"}
                ],
                table: table
            },
            footer: {
                text: "This is the footer content"
            },
            pageEnable: true,
            pageLabel: "Page "
        };
        var colorBlack = "#000000";
        var colorGray = "#4d4e53";
        var docWidth = doc.internal.pageSize.getWidth();
        var docHeight = doc.internal.pageSize.getHeight();
        doc.setFontSize(pdfConfig.headerTextSize);
        doc.text(this.osData.AccountName, 20, currentHeight);
        currentHeight += pdfConfig.subLineHeight;
        currentHeight += pdfConfig.subLineHeight;
        doc.setFontSize(pdfConfig.fieldTextSize);
        doc.setTextColor(colorGray);
        doc.text(this.osData.Address.BillingStreet + ", " + this.osData.Address.BillingCity + ", " + this.osData.Address.BillingState + " " + this.osData.Address.BillingZipCode,20,currentHeight);
        currentHeight += pdfConfig.subLineHeight;

        if (param.logo.src) {
            var imgData = "http://aprenderaprogramar.com/images/thumbs_portada/thumbs_divulgacion/35_errores_en_programacion.jpg";
            var imageHeader = new Image();
            imageHeader.src = imgData;
            console.log(imageHeader);
            //doc.text(htmlDoc.sessionDateText, docWidth - (doc.getTextWidth(htmlDoc.sessionDateText) + 10), currentHeight);
            // doc.addImage(imageHeader, 'JPEG', 15, 40, 180, 160);
        }
        doc.line(20,currentHeight, docWidth - 20, currentHeight);

        doc.setTextColor(colorBlack);
        doc.setFontSize(pdfConfig.headerTextSize - 5);
        currentHeight += pdfConfig.lineHeight;
        currentHeight += pdfConfig.lineHeight;
        doc.text('Selected Products:', 20, currentHeight);
        currentHeight += pdfConfig.subLineHeight;

        //Table part

        var tdWidth = (doc.getPageWidth() - 20) / param.invoice.header.length;
        //#region TD WIDTH
        if (param.invoice.header.length > 2) { //add style for 2 or more columns
            const customColumnNo = param.invoice.header.map(x => x?.style?.width || 0).filter(x => x > 0);
            let customWidthOfAllColumns = customColumnNo.reduce((a, b) => a + b, 0);
            tdWidth = (doc.getPageWidth() - 40 - customWidthOfAllColumns) / (param.invoice.header.length - customColumnNo.length);
        }
        var addTableHeaderBorder = () => {
            currentHeight += 2;
            const lineHeight = 7;
            let startWidth = 10;
            for (let i = 0; i < param.invoice.header.length; i++) {
              const currentTdWidth = param.invoice.header[i]?.style?.width || tdWidth;
              if (i === 0) doc.rect(20, currentHeight, currentTdWidth, lineHeight);
              else {
                const previousTdWidth = param.invoice.header[i - 1]?.style?.width || tdWidth;
                const widthToUse = currentTdWidth == previousTdWidth ? currentTdWidth : previousTdWidth;
                startWidth += widthToUse;
                doc.rect(startWidth + 10, currentHeight, currentTdWidth, lineHeight);
              }
            }
            currentHeight -= 3;
        };
        //#region TABLE BODY BORDER
        var addTableBodyBorder = (lineHeight) => {
            let startWidth = 10;
            for (let i = 0; i < param.invoice.header.length; i++) {
            const currentTdWidth = param.invoice.header[i]?.style?.width || tdWidth;
            if (i === 0) doc.rect(20, currentHeight, currentTdWidth, lineHeight);
            else {
                const previousTdWidth = param.invoice.header[i - 1]?.style?.width || tdWidth;
                const widthToUse = currentTdWidth == previousTdWidth ? currentTdWidth : previousTdWidth;
                startWidth += widthToUse;
                doc.rect(startWidth + 10, currentHeight, currentTdWidth, lineHeight);
            }
            }
        };
        //#endregion
        //#region TABLE HEADER
        var addTableHeader = () => {
            if (param.invoice.headerBorder) addTableHeaderBorder();

            currentHeight += pdfConfig.subLineHeight;
            doc.setTextColor(colorBlack);
            doc.setFontSize(pdfConfig.fieldTextSize);
            //border color
            doc.setDrawColor(colorGray);
            currentHeight += 3;
            let startWidth = 11
            param.invoice.header.forEach(function (row, index) {
            if (index == 0) doc.text(row.title, 22, currentHeight + 1);
            else {
                const currentTdWidth = row?.style?.width || tdWidth;
                const previousTdWidth = param.invoice.header[index - 1]?.style?.width || tdWidth;
                const widthToUse = currentTdWidth == previousTdWidth ? currentTdWidth : previousTdWidth;
                startWidth += widthToUse;
                doc.text(row.title, startWidth + 11, currentHeight + 1);
            }
            });
            currentHeight += pdfConfig.subLineHeight - 1;
            doc.setTextColor(colorGray);
        };
        //#endregion
        addTableHeader();
        // //#region TABLE BODY
        var tableBodyLength = param.invoice.table.length;
        param.invoice.table.forEach(function (row, index) {
            doc.line(20, currentHeight, docWidth - 20, currentHeight);
            //get nax height for the current row
            var getRowsHeight = function () {
            let rowsHeight = [];
            row.forEach(function (rr, index) {
                // const widthToUse = param.invoice.header[index]?.style?.width || tdWidth;
                // let item = splitTextAndGetHeight(rr.toString(), widthToUse - 1); //minus 1, to fix the padding issue between borders
                let item = 7;
                rowsHeight.push(item);
            });
            return rowsHeight;
            };
            var maxHeight = Math.max(...getRowsHeight());

            //body borders
            if (param.invoice.tableBodyBorder) addTableBodyBorder(maxHeight);
            doc.setFontSize(pdfConfig.fieldTextSize);
            doc.setTextColor(colorGray);
            let startWidth = 11;
            row.forEach(function (rr, index) {
            // const widthToUse = param.invoice.header[index]?.style?.width || tdWidth;
        //     let item = splitTextAndGetHeight(rr.toString(), widthToUse - 1); //minus 1, to fix the padding issue between borders
                let item = rr.toString();
            if (index == 0) doc.text(item, 22, currentHeight + 5);
            else {
                const currentTdWidth = rr?.style?.width || tdWidth;
                const previousTdWidth = param.invoice.header[index - 1]?.style?.width || tdWidth;
                const widthToUse = currentTdWidth == previousTdWidth ? currentTdWidth : previousTdWidth;
                startWidth += widthToUse;
                doc.text(item, 11 + startWidth, currentHeight + 5);
            }
            });
            currentHeight += maxHeight - 4;
            //td border height
            currentHeight += 4;

            //pre-increase currentHeight to check the height based on next row
            // if (index + 1 < tableBodyLength) currentHeight += maxHeight;

            if (
            param.orientationLandscape &&
            (currentHeight > 185 ||
                (currentHeight > 178 && doc.getNumberOfPages() > 1))
            ) {
            doc.addPage();
            currentHeight = 10;
            if (index + 1 < tableBodyLength) addTableHeader();
            }
            if (
            !param.orientationLandscape &&
            (currentHeight > 265 ||
                (currentHeight > 255 && doc.getNumberOfPages() > 1))
            ) {
            doc.addPage();
            currentHeight = 10;
            if (index + 1 < tableBodyLength) addTableHeader();
            }
        });
        
        //#region PAGE BREAKER
        var checkAndAddPageLandscape = function () {
            if (!param.orientationLandscape && currentHeight > 270) {
            doc.addPage();
            currentHeight = 10;
            }
        }

        var checkAndAddPageNotLandscape = function (heightLimit = 173) {
            if (param.orientationLandscape && currentHeight > heightLimit) {
            doc.addPage();
            currentHeight = 10;
            }
        }
        //#endregion
        
        checkAndAddPageNotLandscape();
        checkAndAddPageLandscape();
        
        doc.setTextColor(colorBlack);
        doc.setFontSize(pdfConfig.labelTextSize);
        currentHeight += pdfConfig.lineHeight;

        //#region Add num of pages at the bottom
        if (doc.getNumberOfPages() > 1) {
            for (let i = 1; i <= doc.getNumberOfPages(); i++) {
            doc.setFontSize(pdfConfig.fieldTextSize - 2);
            doc.setTextColor(colorGray);

            if (param.pageEnable) {
                // doc.text(param.footer.text, docWidth / 2, docHeight - 10);
                doc.setPage(i);
                doc.text(
                    param.pageLabel + " " + i + " / " + doc.getNumberOfPages(),
                    docWidth - 20,
                    doc.internal.pageSize.height - 6
                );
            }

            checkAndAddPageNotLandscape(183);
            checkAndAddPageLandscape();
            }
        }
        //#endregion

        //#region Add num of first page at the bottom
        if (doc.getNumberOfPages() === 1 && param.pageEnable) {
            doc.setFontSize(pdfConfig.fieldTextSize - 2);
            doc.setTextColor(colorGray);
            // doc.text(param.footer.text, docWidth / 2, docHeight - 10);
            doc.text(
            param.pageLabel + "1 / 1",
            docWidth - 20,
            doc.internal.pageSize.height - 6
            );
        }

        doc.save();
    }
    
}