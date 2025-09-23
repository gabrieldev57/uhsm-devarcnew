import { track, LightningElement, wire, api } from 'lwc';
// import getContract from '@salesforce/apex/ARC_ContractSearchBar.getContractbyCensusMember';
// import getallContracts from '@salesforce/apex/ARC_ContractSearchBar.getAllContractbyCensusMember';
import { NavigationMixin } from 'lightning/navigation';
const DELAY = 300;

export default class UHSM_ContractListCensusMember extends NavigationMixin(LightningElement) {
    // contractNumber='';
    @api recordId;
    // contractIds = '';
    // userId = '';
    // @track contractList =[];
    // @track allContractList =[];

    // @wire(getallContracts,{contractNumber:'$contractNumber', recordId: '$recordId'}) 
    // retrieveContracts({ error, data }) { 
    //     if(data){
    //         let contracts = this.formatContractData(data.lineItems, data);
    //         let auxContracts = this.addPolicyParticipants(contracts, data);
    //         console.log("auxcontracts: "+JSON.stringify(auxContracts))
    //         console.log("data: "+JSON.stringify(data))
    //         this.contractList = auxContracts.filter(item => item.ActMembersId.includes(data.censusMember[0].vlocity_ins__ContactId__c));
    //         console.log("CONTRACTLIST!: "+JSON.stringify(this.contractList))
    //     }
    //     else if(error){
    //         console.error(this.recordId);
    //     }
    // }

    // removeDuplicates(arr) {
    //     var unique = [];
    //     var onlyMedicals = [];
    //     let productName = "";
    //     let newMap = new Map();
    //     let savedContractId = "";
    //     let contractIdList = [];

        
    //     // for (let i = 0; i < arr.length; i++) {
    //     //     savedContractId = arr[i].vlocity_ins__ContractId__c;
    //     //     for(let j = i+1; j < arr.length; j++){
    //     //         if(arr[i]?.vlocity_ins__ContractId__c == arr[j]?.vlocity_ins__ContractId__c){
    //     //             productName += arr[i].vlocity_ins__Product2Id__r.Name + ", "; 
                    
    //     //             newMap[arr[i].vlocity_ins__ContractId__c] = productName;
    //     //        }
    //     //     //     else if (arr[i]?.vlocity_ins__ContractId__c != arr[j]?.vlocity_ins__ContractId__c && arr[i]?.vlocity_ins__ContractId__c == savedContractId){
    //     //     //        productName += arr[i].vlocity_ins__Product2Id__r.Name; 
    //     //     //         newMap[arr[i].vlocity_ins__ContractId__c] = productName;
    //     //     //    }
    //     //        if(arr[i+1]?.vlocity_ins__ContractId__c != savedContractId){
    //     //            productName = "";
    //     //        }
    //     //     }
    //     // }
    //     let listOfCLI = [...arr];
    //     listOfCLI.sort((a,b) => {
    //         let typeA = a.vlocity_ins__Product2Id__r.vlocity_ins__Type__c;
    //         let typeB = b.vlocity_ins__Product2Id__r.vlocity_ins__Type__c;

    //         if(typeA > typeB){
    //             return -1;
    //         }
        
    //         if(typeA < typeB){
    //             return 1;
    //         }

    //         return 0;
    //     });

    //     listOfCLI.forEach(element => {
    //         if(!contractIdList.includes(element.vlocity_ins__ContractId__c)){
    //             contractIdList.push(element.vlocity_ins__ContractId__c);
    //         }
    //     });

    //     contractIdList.forEach(element => {
    //         listOfCLI.filter(item => item.vlocity_ins__ContractId__c == element).forEach(current => {              
    //             productName += current.vlocity_ins__Product2Id__r.Name + ", "; 
    //             newMap[current.vlocity_ins__ContractId__c] = productName;
    //             }
    //         )
    //         productName = "";
    //         newMap[element] = newMap[element].slice(0,-2);
    //     });


    //     console.log("newmap!"+JSON.stringify(newMap))

    //     listOfCLI.filter(item => item.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Medical').forEach(element => {
       
    //         let newElement = JSON.parse(JSON.stringify(element));
    //         let savedProduct = newMap[element.vlocity_ins__ContractId__c];
    //         if(newMap[element.vlocity_ins__ContractId__c]){
    //             newElement.AllPlansNames = savedProduct;
    //             onlyMedicals.push(newElement);
    //         }
    //     });

    //     onlyMedicals.forEach(element => {
    //         if (unique[1]?.vlocity_ins__ContractId__c != element.vlocity_ins__ContractId__c) {
    //             unique.push(element);
    //             // theId = element.vlocity_ins__ContractId__c;
    //         } else {
    //             unique.pop();
    //         }
    //     });
    //     return unique;
    // }   
    
    // formatContractData(contracts, data) {
    //     let formatedContract=[];
    //     let formatedPaidDate;
    //     console.timeLog(JSON.stringify(data))
    //     contracts= this.removeDuplicates(contracts);
    //     console.log("CONTRACTLIST!: "+JSON.stringify(contracts))
    //     // console.log(today.toLocaleDateString("en-US")); // 9/17/2016
    //     contracts.forEach(contract => {
            
    //         let PaidDate = contract.vlocity_ins__ContractId__r.ARC_PaidThroughDate__c;
    //         console.log(PaidDate)
    //         if(PaidDate != undefined && PaidDate != null && PaidDate != ""){
    //             const [year, month, day] = PaidDate.split('-');
    //             formatedPaidDate = [month, day, year].join('/');
    //         } else {
    //             formatedPaidDate = PaidDate;
    //         }
    //         let reprice = false;
    //         let repricedString = "No";
    //         let hasInactiveDate = false;
    //         let hasCancellationReason = false;
    //         if (contract?.vlocity_ins__ContractId__r?.ARC_Inactive_Date__c != null) {
    //             hasInactiveDate = true;
    //         }
    //         if (contract?.vlocity_ins__ContractId__r?.ARC_CancellationReason__c != null) {
    //             hasCancellationReason = true;
    //         }
    //         if (contract?.vlocity_ins__ContractId__r?.ARC_Case__r?.ARC_repricedContract__c && contract.vlocity_ins__ContractId__r?.Status != "Terminated") {
    //             reprice = true;
    //             repricedString = "Yes";
    //         }
    //         let userName = 'No Agent';
    //         let singleReason = '';
    //         let planNames = contract.AllPlansNames;
    //         if(contract.vlocity_ins__ContractId__r.ARC_Selling_Agent__c != undefined){
    //             userName = contract.vlocity_ins__ContractId__r.ARC_Selling_Agent__r.Name;
    //             singleReason = contract.vlocity_ins__ContractId__r.ARC_SingleReasonForPC__c;
    //             if(singleReason?.includes('Add Ancillary Product')){
    //                 singleReason = singleReason.replace('Add Ancillary Product', 'Ancillary Change');
    //             }
              
    //         }
         
    //         if((contract.vlocity_ins__ContractId__r.ARC_ContractReason__c == "New Application" || contract.vlocity_ins__ContractId__r.ARC_ContractReason__c == "Upgraded Spin Off" || contract.vlocity_ins__ContractId__r.ARC_ContractReason__c == "Spin Off Add Member" || contract.vlocity_ins__ContractId__r.ARC_ContractReason__c == "Spin Off") && contract.vlocity_ins__ContractId__r.Status != "Draft"){
    //             formatedContract.push({
    //                 Id: contract.vlocity_ins__ContractId__c,
    //                 OwnerId: contract.vlocity_ins__ContractId__r.OwnerId,
    //                 ContractNumber: contract.vlocity_ins__ContractId__r.ContractNumber,
    //                 ARC_EffectiveDate__c: contract.vlocity_ins__ContractId__r.ARC_EffectiveDate__c,
    //                 Status: contract.vlocity_ins__ContractId__r.Status,
    //                 PaidThrough: formatedPaidDate,
    //                 ARC_Inactive_Date__c: contract.vlocity_ins__ContractId__r.ARC_Inactive_Date__c,
    //                 // PlanName: planNames,
    //                 PlanName: planNames,
    //                 hasInactiveDate: hasInactiveDate,
    //                 Reason: contract.vlocity_ins__ContractId__r.ARC_ContractReason__c,
    //                 CancellationReason:contract.vlocity_ins__ContractId__r.ARC_CancellationReason__c,
    //                 hasCancellationReason: hasCancellationReason,
    //                 Repriced: reprice,
    //                 RepricedString: repricedString,
    //                 Agent: userName
    //             });
    //         } else if(contract.vlocity_ins__ContractId__r.Status != "Draft"){
    //             formatedContract.push({
    //                 Id: contract.vlocity_ins__ContractId__c,
    //                 OwnerId: contract.vlocity_ins__ContractId__r.OwnerId,
    //                 ContractNumber: contract.vlocity_ins__ContractId__r.ContractNumber,
    //                 ARC_EffectiveDate__c: contract.vlocity_ins__ContractId__r.ARC_EffectiveDate__c,
    //                 Status: contract.vlocity_ins__ContractId__r.Status,
    //                 PaidThrough: formatedPaidDate,
    //                 ARC_Inactive_Date__c: contract.vlocity_ins__ContractId__r.ARC_Inactive_Date__c,
    //                 PlanName: planNames,
    //                 hasInactiveDate: hasInactiveDate,
    //                 Reason: singleReason,
    //                 CancellationReason:contract.vlocity_ins__ContractId__r.ARC_CancellationReason__c,
    //                 hasCancellationReason: hasCancellationReason,
    //                 Repriced: reprice,
    //                 RepricedString: repricedString,
    //                 Agent: userName
    //             });
    //         }
    //     });
    //     return formatedContract;
    // }

    // addPolicyParticipants(cont, data){
    //     cont.forEach(contract => {
    //         const filtParti = data.polPart.filter(part => part.InsurancePolicy.ARC_Contract__c == contract.Id);

    //         // const nameList = filtParti.map(item => {
    //         //     if (item.PrimaryParticipantContact) return item.PrimaryParticipantContact.Name;
    //         // })
    //         let nameList = [];
    //         let idList = [];    
    //         filtParti.forEach(element => {
    //             if (element.PrimaryParticipantContact /*&& !nameList?.includes(element.PrimaryParticipantContact.Name)*/){
    //                 nameList?.push(element.PrimaryParticipantContact.Name);
    //                 idList?.push(element.PrimaryParticipantContact.Id);
    //             }
    //         });

    //         contract['ActMembersName'] = nameList.join(', ');
    //         contract['ActMembersId'] = idList.join(', ');
    //     })

    //     return cont;
    // }

    // handleKeyChange(event){
    //     const searchString= event.target.value;
    //     window.clearTimeout(this.delayTimeout);
    //     this.delayTimeout = setTimeout(()=>{
    //         this.contractNumber =searchString;
    //     },DELAY);
    // }

    // newContract(event) {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__objectPage',
    //         attributes: {
    //             recordId: event.currentTarget.dataset.id,
    //             objectApiName: 'Contract',
    //             actionName: 'new'
    //         },
    //     });
    // }

    // viewRecord(event) {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             recordId: event.currentTarget.dataset.id,
    //             objectApiName: 'Contract',
    //             actionName: 'view'
    //         },
    //     });
    // }

    // editRecord(event) {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             recordId: event.currentTarget.dataset.id,
    //             objectApiName: 'Contract',
    //             actionName: 'edit'
    //         },
    //     });
    // }

    // viewOwner(event) {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             recordId: event.currentTarget.dataset.ownerid,
    //             objectApiName: 'User',
    //             actionName: 'view'
    //         },
    //     });
    // }
    // cancelContract(event) {
        
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__webPage',
    //         attributes: {
    //             url: '/lightning/cmp/vlocity_ins__vlocityLWCOmniWrapper?c__target=c%3AindividualAndFamilyProgramCancellationEnglish&c__layout=newport&c__ContextId='+this.recordId+'&c__ContractId='+event.currentTarget.dataset.id
                
    //         },
            
    //     });

        
    //     console.log('CONTRACT ID'+' '+ event.currentTarget.dataset.id);
      
   
    
    // }
}