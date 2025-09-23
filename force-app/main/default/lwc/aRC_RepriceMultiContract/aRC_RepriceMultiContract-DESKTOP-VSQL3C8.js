import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_RepriceMultiContract extends OmniscriptBaseMixin(LightningElement) {
    @api reprice;
    @api beforereprice;
    LB_UserInputs = [];
    isLoading = true;
    changesForContracts = [];
    ContractCreation = {};

    connectedCallback() {
        if (this.beforereprice) {
            
            const prom = new Promise((resolve, reject) => {
                this.reprice.forEach(change => {
                    let LB_UserInputsItem = {RA_GetProductDetails: { records:[] }}
    
                    const prom2 = new Promise((res, rej) => {
                        change.productList.forEach(prod => {
                            let repricedProduct;
                            let item = {userInputs: prod.userInputs}
            
                            const remoteOptions = {
                                includeRawCalculationResult: true,
                                whereClause: "Id = '" + prod.selectedProduct.Id + "'",
                            }
                            const params = {
                                input: JSON.stringify(item),
                                sClassName: 'InsProductService',
                                sMethodName: 'getRatedProducts',
                                options: JSON.stringify(remoteOptions),
                            };
                            this.omniRemoteCall(params, true).then(response => {
                                repricedProduct = response.result.records[0];
                            }).catch(error => {
                                console.error('error',error);
                            }).finally(() => {


                                delete repricedProduct['attributeCategories'];
                                delete repricedProduct['RawPriceData'];
                                delete repricedProduct['CalculatedPriceData'];
                                repricedProduct.childProducts.records.forEach(cprod => {
                                    delete cprod['attributeCategories'];
                                });
                                


                                LB_UserInputsItem.RA_GetProductDetails.records.push(repricedProduct);

                                LB_UserInputsItem.RA_GetProductDetails.records.length == change.productList.length && res('success');
                            });
                        });
                    })
                    prom2.then(() => {
                        LB_UserInputsItem.productList = change.productList;
                        LB_UserInputsItem.Reason = change.Reason;
                        LB_UserInputsItem.ProductsToUpdate = change.ProductsToUpdate;
                        LB_UserInputsItem.selectedProducts = change.selectedProducts;
                        LB_UserInputsItem.RemovedMembers = change.RemovedMembers;
                        LB_UserInputsItem.auxSavedMembers = change.auxSavedMembers;
                        LB_UserInputsItem.accountId = change.accountId;
                        LB_UserInputsItem.caseId = change.caseId;
                        LB_UserInputsItem.censusId = change.censusId;
                        LB_UserInputsItem.Id = change.Id;
                        LB_UserInputsItem.effectiveDate = change.EffDate;
                        LB_UserInputsItem.SingleReason = change.SingleReason;
                        LB_UserInputsItem.userInputs2 = change.userInputs2;
                        LB_UserInputsItem.SingleReasonToDisplay = change.SingleReasonToDisplay;
                        // this.LB_UserInputs.push(LB_UserInputsItem);
                        // this.LB_UserInputs.length == this.reprice.length && resolve('success');
                        let SV_SumAllProducts = { SubTotal: 0, MedicalProduct: { Name: 'test', Price: 0 } };
                        let SV_SumAllProductsPlusFee = { ChargeAmount: '' };

                        //=SUM(%LB_UserInputs:RA_GetProductDetails:records:Price%)
                        SV_SumAllProducts.SubTotal = LB_UserInputsItem.RA_GetProductDetails.records.reduce((accumulator, object) => {
                            return accumulator + object.Price;
                        }, 0);
                        //=FILTER(LIST(%LB_UserInputs:RA_GetProductDetails:records%),'Type__c == "Medical"')
                        SV_SumAllProducts.MedicalProduct = LB_UserInputsItem.RA_GetProductDetails.records.filter(prod => prod.Type__c == 'Medical')[0];
                        
                        //=SUM(%LB_UserInputs:RA_GetProductDetails:records:Price%)
                        SV_SumAllProductsPlusFee.ChargeAmount = SV_SumAllProducts.SubTotal;
                        this.changesForContracts.push({
                            UnderwritingCase: LB_UserInputsItem.caseId,
                            contractCreated: LB_UserInputsItem.Id,
                            SV_SumAllProductsPlusFee: SV_SumAllProductsPlusFee,
                            TotalPricePlusFee: SV_SumAllProductsPlusFee.ChargeAmount,
                            MedicalName: SV_SumAllProducts.MedicalProduct.Name,
                            TotalPrice: SV_SumAllProducts.SubTotal,
                            MedicalPrice: SV_SumAllProducts.MedicalProduct.Price,
                            ContractId: LB_UserInputsItem.Id,
                            Id: LB_UserInputsItem.Id,
                            NewContractTotalPrice: SV_SumAllProducts.SubTotal,
                            effectiveDate: LB_UserInputsItem.effectiveDate,
                            singleReason: LB_UserInputsItem.Reason,
                            Reason: LB_UserInputsItem.Reason,
                            SingleReason: LB_UserInputsItem.SingleReason,
                            singleReasonToDisplay: LB_UserInputsItem.SingleReasonToDisplay,
                            SingleReasonToDisplay: LB_UserInputsItem.SingleReasonToDisplay,
                            listSize: LB_UserInputsItem.listSize,
                            productList: LB_UserInputsItem.productList,
                            userInputs2: LB_UserInputsItem.userInputs2,
                            RemovedMembers: LB_UserInputsItem.RemovedMembers,
                            auxSavedMembers: LB_UserInputsItem.auxSavedMembers,
                            RA_GetProductDetails: LB_UserInputsItem.RA_GetProductDetails,
                            caseId: LB_UserInputsItem.caseId,
                            censusId: LB_UserInputsItem.censusId,
                            accountId: LB_UserInputsItem.accountId,
                            ProductsToUpdate: LB_UserInputsItem.ProductsToUpdate,
                            selectedProducts: LB_UserInputsItem.selectedProducts,
                            EffDate: LB_UserInputsItem.effectiveDate,
                        });
                        this.changesForContracts.length == this.reprice.length && resolve("success");
                    });
                });

            })
            prom.then(() => {
                let dates = this.changesForContracts.map(object => { return  object.effectiveDate })
                let lastEffDate = dates.reduce((a, b) => a > b ? a : b);
    
                this.changesForContracts.forEach(LB_UserInputsItem => {
                    if (lastEffDate == LB_UserInputsItem.effectiveDate) {
                        this.ContractCreation.FilterProgramsToUpdate = LB_UserInputsItem;
                    }
                });

                //where starts calculate prices IP
                let LB_changesForContracts = [];
                //LB_ChangesForContracts

                this.ContractCreation.changesForContracts = this.changesForContracts;
                this.ContractCreation.FirstContract = this.changesForContracts[0];
                this.ContractCreation.FutureContracts = this.changesForContracts.filter(item => item.ContractId != this.changesForContracts[0].ContractId);
                this.ContractCreation.UnderwritingCase = this.changesForContracts[0].UnderwritingCase;
                


                

    
                this.omniUpdateDataJson({ ContractCreation: this.ContractCreation } );
                this.omniNextStep();
            })
        } else {
            this.omniPrevStep();
        }
    }
}