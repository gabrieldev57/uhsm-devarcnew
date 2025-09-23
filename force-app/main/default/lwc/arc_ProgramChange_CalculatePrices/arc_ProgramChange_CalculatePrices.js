import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class Arc_ProgramChange_CalculatePrices extends OmniscriptBaseMixin(LightningElement) {

    @api plans;
    @api execute_reprice_flag;
    @api effective_date;
    @api is_removemember_spinoff;
    
    calculation_result = [];
    
    connectedCallback() {
        this.is_removemember_spinoff = this.is_removemember_spinoff == undefined || this.is_removemember_spinoff == null ? false : this.is_removemember_spinoff;

        // console.log('this.is_removemember_spinoff ' + this.is_removemember_spinoff)
        // console.log('this.omniJsonData.repriceStepState ' + this.omniJsonData.repriceStepState)
        // console.log('this.plans', JSON.stringify(this.plans));
        // console.log('this.execute_reprice_flag', this.execute_reprice_flag);
        // console.log('this.effective_date', this.effective_date);
        if (this.execute_reprice_flag == true && this.plans && this.effective_date) {
            this.calculatePrices();
        } else {
            this.omniPrevStep();
        }
    }
    
    
    calculatePrices() {
        const promise = new Promise((res, rej) => {
            this.plans.forEach(plan => {
                let result;
                const input = { userInputs: plan.userInputs }
                const options = {
                    includeRawCalculationResult: true,
                    effectiveDate: this.effective_date,
                    whereClause: "Id = '" + plan.selectedProduct.Id + "'",
                }
                const params = {
                    input: JSON.stringify(input),
                    sClassName: 'InsProductService',
                    sMethodName: 'getRatedProducts',
                    options: JSON.stringify(options),
                };
                this.omniRemoteCall(params, true).then((response) => {
                    console.log('params', params);
                    console.log('response', response);
                    if (response.result.records) {
                        result = response.result?.records[0];
                        this.calculation_result.push({
                            selectedProduct: result,
                            userInputs: plan.userInputs,
                        });
                    }
                }).catch(error => {
                    console.error('error', error);
                }).finally(() => {
                    if (result) {
                        delete result['CalculatedPriceData'];
                        result.childProducts.records.forEach(childProduct => {
                            delete childProduct['attributeCategories'];
                        });
                    }
                    this.calculation_result.length == this.plans.length && res('success');
                });
                
            });
            
            
        });
        promise.then(() => {
            const responseKey = this.is_removemember_spinoff ? 'price_calculation_removemember_spinoff' : 'price_calculation';
            console.log('this.responseKey' + responseKey);
            this.omniApplyCallResp({
                [responseKey]: {
                    'plans': this.calculation_result,
                },
                'execute_reprice_flag': false
            });
        }).catch(error => {
            console.error('error', error);
        }).finally(() => {
            this.omniNextStep();
        });
    }
}
/* 

{
"plans": [
    {
        "productId": "01t5f000003xhmUAAQ",
        "userInputs": [
            {
                "RF_Census.CRF_ExtraDependants": 0,
                "RF_Census.CRF_CoverageAIDD": "Family",
                "RF_Census.CRF_Coverage": "Family",
                "RF_Census.CRF_Dependants": true,
                "RF_Census.CRF_PrimaryMemberAge": 61,
                "RF_Census.CM_Smoker": true,
                "RF_Census.CM_Age": 61,
                "RF_Census.CM_IsPrimary": true,
                "RF_Census.CM_State": "LA"
            },
            {
                "RF_Census.CRF_ExtraDependants": 0,
                "RF_Census.CRF_CoverageAIDD": "Family",
                "RF_Census.CRF_Coverage": "Family",
                "RF_Census.CRF_Dependants": true,
                "RF_Census.CRF_PrimaryMemberAge": 61,
                "RF_Census.CM_Smoker": false,
                "RF_Census.CM_Age": 28,
                "RF_Census.CM_IsPrimary": false,
                "RF_Census.CM_State": "LA"
            },
            {
                "RF_Census.CRF_ExtraDependants": 0,
                "RF_Census.CRF_CoverageAIDD": "Family",
                "RF_Census.CRF_Coverage": "Family",
                "RF_Census.CRF_Dependants": true,
                "RF_Census.CRF_PrimaryMemberAge": 61,
                "RF_Census.CM_Age": 20,
                "RF_Census.CM_IsPrimary": false,
                "RF_Census.CM_State": "LA",
                "RF_Census.CM_Smoker": false
            }
        ]
    },
    {
        "productId":: "01t5f000003xhfJAAQ",
        "userInputs": [
            {
                "RF_Census.CRF_ExtraDependants": 0,
                "RF_Census.CRF_CoverageAIDD": "Family",
                "RF_Census.CRF_Coverage": "Family",
                "RF_Census.CRF_Dependants": true,
                "RF_Census.CRF_PrimaryMemberAge": 61,
                "RF_Census.CM_Smoker": false,
                "RF_Census.CM_Age": 28,
                "RF_Census.CM_IsPrimary": false,
                "RF_Census.CM_State": "LA"
            }
        ]
    },
    {
        "productId": "01t5f000003xhfJAAQ",
        "userInputs": [
            {
                "RF_Census.CRF_ExtraDependants": 0,
                "RF_Census.CRF_CoverageAIDD": "Family",
                "RF_Census.CRF_Coverage": "Family",
                "RF_Census.CRF_Dependants": true,
                "RF_Census.CRF_PrimaryMemberAge": 61,
                "RF_Census.CM_Smoker": true,
                "RF_Census.CM_Age": 61,
                "RF_Census.CM_IsPrimary": true,
                "RF_Census.CM_State": "LA"
            },
            {
                "RF_Census.CRF_ExtraDependants": 0,
                "RF_Census.CRF_CoverageAIDD": "Family",
                "RF_Census.CRF_Coverage": "Family",
                "RF_Census.CRF_Dependants": true,
                "RF_Census.CRF_PrimaryMemberAge": 61,
                "RF_Census.CM_Age": 20,
                "RF_Census.CM_IsPrimary": false,
                "RF_Census.CM_State": "LA",
                "RF_Census.CM_Smoker": false,
            }
        ]
    }
]
}
*/