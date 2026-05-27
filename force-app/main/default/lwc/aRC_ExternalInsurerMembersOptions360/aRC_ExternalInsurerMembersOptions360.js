import { LightningElement,api,track } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";

export default class ARC_ExternalInsurerMembersOptions360 extends OmniscriptBaseMixin(LightningElement){
    selectedSource;
    membersData=[];
    dataError = false;
    showExternalInsurance = false;
    @track externalInsuranceInstances=[
        {
            id: 1,
            insurer:"",
            policyNumber:"",
            effectiveDate:null,
            expirationDate:null,
            insurerPhone:"",
            sourceOfCoverage:"", 
            policyMembers:[]
        }
    ];
    @api options;
    @api relatedAccounts;

    handleChangeSource(event) {
        this.selectedSource = event.detail.value;
    }

    async connectedCallback(){
        console.log('connectedCallback OmniJsonData: ' + this.omniJsonData);
        console.log('connectedCallback censusMemberId: ' + this.omniJsonData.CensusMemberId);
        const params = {
			input: JSON.stringify({
				'object': 'ARC_ExternalInsurancePolicy__c',
				'field': 'ARC_SourceOfCoverage__c',
			}),
			sClassName: 'ARC_ReadPicklistValues',
			sMethodName: 'returnPicklistValuesAsAList',
			options: '{}',
		};
		const response = await this.omniRemoteCall(params, true)
        this.options = response.result.response
    }

    initialRender = true;
    renderedCallback() {

        if (!this.initialRender) {
            return;
        }
        
            console.log('enter Account360 processing');

            this.omniJsonData.RelatedAccounts.forEach(member => {
                let memberOption = { Name:member.Name, Id:member.Census_Member__c }
                this.membersData.push(memberOption);
            });

            this.showExternalInsurance = true; 
            
            this.externalInsuranceInstances.forEach(item => {
                item.policyMembers.forEach(member => {
                    console.log('entro al each de los members 360',member);
                    setTimeout(() => {
                        const element = this.template.querySelector(`[data-member='${member.id}'][data-exid='${item.id}']`)
                        if(element) element.checked = true
                    }, 250);
                })
            })
            this.initialRender = false;
            return;
    }


    handleAddButton(){
        this.externalInsuranceInstances.push({
            id: this.externalInsuranceInstances.length + 1,
            insurer:"",
            policyNumber:"",
            effectiveDate:null,
            expirationDate:null,
            insurerPhone:"",
            sourceOfCoverage:"", 
            policyMembers:[]
        })
    }

    handleRemoveButton(e){
        this.externalInsuranceInstances = this.externalInsuranceInstances.filter(item => item.id != e.currentTarget.dataset.id)
    }

    handleChange(event){
        const field = event.currentTarget.dataset.input;
        const externalId = event.currentTarget.dataset.exid;
        this.dataError = false;
        if(field == 'memberData'){
            const member = event.target.dataset.member;
            const mData = this.membersData.find(element=> element.Id == member)
            const handleData = action => {
                const newObj = this.externalInsuranceInstances.map(item => {
                    if (item.id == externalId && action == 'add') {
                        return {
                          ...item,
                          policyMembers: [...item.policyMembers, { name: mData.Name, id: mData.Id }],
                        }
                    }else if(item.id == externalId && action == 'remove'){
                        return {
                            ...item,
                            policyMembers: item.policyMembers.filter(value => value.id !== member),
                        }
                    }
                    return item;
                })
                this.externalInsuranceInstances = newObj
            }

            event.target.checked ? handleData('add') : handleData('remove') 
        }else {
            const newObj = this.externalInsuranceInstances.map(item => {
                if(item.id == externalId){
                    return {...item, [field]: event.target.value}
                }
                return item
            })
            this.externalInsuranceInstances = newObj;
        }
    }

    handleNext(){
        this.externalInsuranceInstances.forEach(item => {
            if(
                !item?.policyMembers?.length ||
                item.insurer == null || item.insurer == '' ||
                item.effectiveDate == null || item.effectiveDate == '' ||
                item.expirationDate == null || item.expirationDate == '' 
            ){
                console.log('dataError')
                this.dataError = true;
            }
        })

        if (!this.dataError) {
            this.omniUpdateDataJson(this.externalInsuranceInstances);
            this.omniNextStep();
        }

    }
    
    // new
    handleShowForm(){
        // this.valueRadio = 'Yes' // ?
        this.showExternalInsurance = !this.showExternalInsurance;
    } 

}