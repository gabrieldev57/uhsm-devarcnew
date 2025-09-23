import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_RepriceMultiContract extends OmniscriptBaseMixin(LightningElement) {
    @api reprice;
    @api beforereprice;
    LB_UserInputs = [];
    isLoading = true;
    changesForContracts = [];
    ContractCreation = {};
    selectedProducts = [];
    createSelProd = true;
    includeNewMembersInUpgrade = false;

    connectedCallback() {
        let auxReprice = JSON.parse(JSON.stringify(this.reprice));
        console.log('this.reprice', this.reprice);
        if (this.beforereprice) {
            auxReprice.forEach(change => {
                change.productList.forEach(pItem => {
                    pItem.selectedProduct?.childProducts?.records.forEach(cprod => {
                        cprod.attributeCategories = null;
                    });
                });

                if (Array.isArray(change.selectedProducts)) {
                    change.selectedProducts?.forEach(selItem => {
                        selItem.childProducts?.records.forEach(cprod => {
                            cprod.attributeCategories = null; 
                        });
                    });
                }
                if (this.createSelProd) {
                    this.selectedProducts = change.selectedProducts;
                    this.createSelProd = false;
                }
            
                if ( change.SingleReason.includes('Program Upgrade') && ( change.Reason.includes('Add Member') || change.Reason.includes('Add Newborn')) && !( change.SingleReason.includes('Add Member') || change.SingleReason.includes('Add Newborn') ) ) {
                    this.includeNewMembersInUpgrade = true;
                }
            });
            const prom = new Promise((resolve, reject) => {
                auxReprice.forEach(change => {
                    let LB_UserInputsItem = {RA_GetProductDetails: { records:[] }}
                    const prom2 = new Promise((res, rej) => {
                        change.productList.forEach(prod => {
                            // console.log('prod',prod);
                            let repricedProduct;
                            let item = {userInputs: prod.userInputs}
                            // console.log('input', item);
                            const remoteOptions = {
                                includeRawCalculationResult: true,
                                effectiveDate: change.EffDate,
                                whereClause: "Id = '" + prod.selectedProduct.Id + "'",
                            }
                            const params = {
                                input: JSON.stringify(item),
                                sClassName: 'InsProductService',
                                sMethodName: 'getRatedProducts',
                                options: JSON.stringify(remoteOptions),
                            };
                            this.omniRemoteCall(params, true).then(response => {
                                console.log('input',prod);
                                // console.log('input', item);
                                console.log('repricedProduct', response);
                                if (response.result.records) {
                                    repricedProduct = response.result?.records[0];
                                }
                                
                            }).catch(error => {
                                console.error('error',error);
                            }).finally(() => {

                                if (repricedProduct) { 

                                    // delete repricedProduct['RawPriceData'];
                                    delete repricedProduct['CalculatedPriceData'];
                                    repricedProduct.childProducts.records.forEach(cprod => {
                                        delete cprod['attributeCategories'];
                                    });
                                    
    
                                    prod.selectedProduct.Price = repricedProduct.Price;
                                    LB_UserInputsItem.RA_GetProductDetails.records.push(repricedProduct);
                                    console.log('LB_UserInputsItem.RA_GetProductDetails.records',LB_UserInputsItem.RA_GetProductDetails.records);
                                    console.log('LB_UserInputsItem.RA_GetProductDetails.records',LB_UserInputsItem.RA_GetProductDetails.records.length);
                                    console.log('change.productList', change.productList);
                                    console.log('change.productList', change.productList.length);
                                    LB_UserInputsItem.RA_GetProductDetails.records.length == change.productList.length && res('success');
                                }
                                // delete repricedProduct['attributeCategories'];
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
                        SV_SumAllProducts.SubTotal = 0;

                        LB_UserInputsItem.RA_GetProductDetails.records.forEach(element => {
                            SV_SumAllProducts.SubTotal = SV_SumAllProducts.SubTotal + (element.Price === '' ? 0 : element.Price);
                        });
                        // // Round 2 decimal places
                        SV_SumAllProducts.SubTotal = Math.round(SV_SumAllProducts.SubTotal * 100)/100;

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
                        console.log('this.changesForContracts',this.changesForContracts);
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
                console.log('this.ContractCreation.FilterProgramsToUpdate', this.ContractCreation.FilterProgramsToUpdate);
                this.ContractCreation.FilterProgramsToUpdate.productList.forEach(prod => { 
                    console.log('prod',prod);
                    console.log('aa',this.ContractCreation.FilterProgramsToUpdate.RA_GetProductDetails.records.find(prod2 => prod2.Id == prod.selectedProduct.Id));
                    // prod.selectedProduct.Price = this.ContractCreation.FilterProgramsToUpdate.RA_GetProductDetails.records.find(prod2 => prod2.Id == prod.selectedProduct.Id).Price;
                });
                this.ContractCreation.changesForContracts = this.changesForContracts;
                this.ContractCreation.FirstContract = this.changesForContracts[0];
                this.ContractCreation.FutureContracts = this.changesForContracts.filter(item => item.ContractId != this.changesForContracts[0].ContractId);
                this.ContractCreation.UnderwritingCase = this.changesForContracts[0].UnderwritingCase;
                


                

    
                this.omniApplyCallResp({
                    changesForContracts: this.ContractCreation.changesForContracts,
                    FirstContract: this.ContractCreation.FirstContract,
                    FutureContracts: this.ContractCreation.FutureContracts,
                    UnderwritingCase: this.ContractCreation.UnderwritingCase,
                    FilterProgramsToUpdate: this.ContractCreation.FilterProgramsToUpdate,
                    selectedProducts: this.selectedProducts,
                    includeNewMembersInUpgrade: this.includeNewMembersInUpgrade
                });
                this.omniNextStep();
            })
        } else {
            this.omniPrevStep();
        }
    }
}