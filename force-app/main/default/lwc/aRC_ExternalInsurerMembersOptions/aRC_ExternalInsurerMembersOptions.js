import { LightningElement,api,track } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";


export default class ARC_ExternalInsurerMembersOptions extends OmniscriptBaseMixin(LightningElement){
    selectedSource;
    membersData=[];
    dataError = false;
    showExternalInsurance = false;
    @track valueRadio = 'No';
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


    get nextBtn(){
        return (this.externalInsuranceInstances.length > 0 && this.valueRadio =='Yes') || this.valueRadio == 'No';
    }

    get optionsRadio(){
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }

    handleChangeSource(event) {
        this.selectedSource = event.detail.value;
    }

    async connectedCallback(){
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
        
        this.omniJsonData.userInputs2.forEach(member => {
            let memberOption = { Name:member.CensusMemberName, Id:member.CensusMemberId }
            this.membersData.push(memberOption);
        });
        if(this.omniJsonData?.STEP_CurrentCoverage?.LWC_ExternalInsurancePolicyStep?.length > 0){
            this.externalInsuranceInstances = this.omniJsonData.STEP_CurrentCoverage.LWC_ExternalInsurancePolicyStep.map(item => item);
            console.log(JSON.stringify(this.externalInsuranceInstances));
            this.valueRadio = 'Yes';
            this.showExternalInsurance=true;
            // this.labelValue = 'No';

            // CHECK CHECKBOXES
            this.externalInsuranceInstances.forEach(item => {
                item.policyMembers.forEach(member => {
                    console.log('entro al each de los members ',member);
                    setTimeout(() => {
                        const element = this.template.querySelector(`[data-member='${member.id}'][data-exid='${item.id}']`)
                        if(element) element.checked = true
                    }, 250);
                })
            })
        }
        else this.showExternalInsurance=false;

        this.initialRender = false;
    }

    handleChangeRadio(e){
        console.log(e.target.value);
        this.valueRadio = e.target.value;
        this.showExternalInsurance = this.valueRadio == 'Yes' ? true:false;
        console.log(this.valueRadio);
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
                item.policyNumber == null || item.policyNumber == '' ||
                item.effectiveDate == null || item.effectiveDate == '' ||
                item.expirationDate == null || item.expirationDate == '' ||
                item.insurerPhone == null || item.insurerPhone == '' ||
                item.sourceOfCoverage == null || item.sourceOfCoverage == ''
            ){
                this.dataError = true;
            }
        })

        if (!this.dataError || this.valueRadio=='No') {
            this.valueRadio == 'No' ? this.omniUpdateDataJson([]) : this.omniUpdateDataJson(this.externalInsuranceInstances);
            this.omniNextStep();
        }

    }
    
    handlePrev(){
        this.valueRadio == 'No' ? this.omniUpdateDataJson([]) : this.omniUpdateDataJson(this.externalInsuranceInstances);
        this.omniPrevStep();
    }
}