import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const columns = [
	{ label: 'Name', fieldName: 'Id', type: 'url', typeAttributes: { label: { fieldName: 'FullName' }, target: '_blank' } },
	{ label: 'Relationship', fieldName: 'Relationship', type: 'text', hideDefaultActions: true },
	{ label: 'Active Date', fieldName: 'MemberStartDate', type: 'text', hideDefaultActions: true },
	{ label: 'Inactive Date', fieldName: 'MemberEndDate', type: 'text', hideDefaultActions: true },
	{ label: 'Email', fieldName: 'Email', type: 'Email' },
	{ label: 'SSN', fieldName: 'SSN', type: 'text' },
	{ label: 'Age', fieldName: 'Age', type: 'text' },
	{ label: 'Hipaa', fieldName: 'isHipaa', type: 'boolean' },	
	{ label: 'Active', fieldName: 'isActive', type: 'boolean' }
];

export default class aRC_DinamicTable extends NavigationMixin(LightningElement) {
	@api records;
	columns = columns;
	@api
	get recordsList() {
		const records = JSON.stringify(this.records);
		const CensusMembers = JSON.parse(records);
		for (let i = 0; i < CensusMembers.length; i++) {
			if (CensusMembers[i]["_children"].length == 0) {
				delete CensusMembers[i]["_children"];
				// CensusMembers[i].NumberOfDependents = 0;
			}

		}
		// delete CensusMembers[0].Id;
		// delete CensusMembers[0].uniqueKey;
		// delete CensusMembers[0]._flex;
		return CensusMembers;
	}

	renderedCallback() {
		const grid = this.template.querySelector('lightning-tree-grid');
		grid.expandAll();
	}


}