import { LightningElement, wire } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';



export default class ARC_SelectPayorHandler extends OmniscriptBaseMixin(LightningElement) {

    fields = [
        {
            fieldName: 'firstName',
            value: "TXT_FirstName"
        },
        {
            fieldName: 'lastName',
            value: "TXT_LastName"
        },
        {
            fieldName: 'street',
            value: "TXT_UpdateBillingAddress_Street"
        },
        {
            fieldName: 'city',
            value: "TXT_UpdateBillingAddress_City"
        },
        {
            fieldName: 'state',
            value: "TXT_UpdateBillingAddress_State"
        },
        {
            fieldName: 'zip',
            value: "TXT_UpdateBillingAddress_ZipCode"
        },
        {
            fieldName: 'phone',
            value: "TXT_Phone"
        },
        {
            fieldName: 'email',
            value: "TXT_Email"
        },
    ];

    fieldsPath = {
        'Credit Card': 'BLK_UpdateCreditCard',
        'Bank Account': 'BLK_BankAccount'
    };


    processing = false;

    get paymentMethod() {
        return this.omniJsonData?.STEP_ChooseMethod?.RAD_MethodOfPayment;
    }

    connectedCallback() {
        if (this.omniJsonData?.selectedPayor) {
            this.selectedPayor = this.omniJsonData.selectedPayor;
            this.handlePayorChange({ target: { value: this.selectedPayor } });
        }
    }

    handleClick() {
        console.log('omniJsonData', this.omniJsonData);
    }

    selectedPayor;

    get payorOptions() {
        return this.omniJsonData.payorOptions;
    }

    get isETFRequired() {
        return this.omniJsonData?.STEP_ChooseMethod?.RAD_ETFRequired === 'Yes';
    }

    handlePayorChange(event) {

        this.selectedPayor = event.target.value;
        this.omniApplyCallResp({
            ...this.processMemberData(this.payorOptions.find(payor => payor.value === this.selectedPayor)),
            selectedPayor: this.selectedPayor
        });

    }






    processMemberData(memberData) {
        // console.log('paymentMethod', this.paymentMethod);
        // console.log('memberData', memberData);
        // console.log('memberDataString', JSON.stringify(memberData));
        // console.log('memberDataParse', JSON.parse(JSON.stringify(memberData)));
        let memberDataCopy = JSON.parse(JSON.stringify(memberData));
        console.log('memberDataCopy', memberDataCopy);
        if (this.paymentMethod && memberDataCopy) {
            for (let field of this.fields) {
                const fieldName = field.value;
                const fieldData = memberDataCopy[field.fieldName];
                if (fieldName) {
                    if (memberData.value == 'Third Party Payor') {
                        memberDataCopy[fieldName] = '';
                    } else {
                        memberDataCopy[fieldName] = fieldData;

                    }
                }
            }

            // Prepare the JSON structure to include member data in the correct node dynamically
            let processedJson = {
                Step_Instructions: {
                    ...JSON.parse(JSON.stringify(memberDataCopy))
                }
            };
            // Call the OmniApplyCallResp with the structured data
            return processedJson;

        }
    }
}