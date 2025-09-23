import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDependencies from '@salesforce/apex/ARC_CheckDependencies.checkDependencies';
export default class POC_CheckDependencies extends LightningElement {
    dependencies;
    componentName;
    handleComponentNameChange(event) {
        this.componentName = event.target.value;
    }

    @wire(getDependencies, {
        componentName: '$componentName',
    }) getDependencies(result) {
        if (result.data) {
            console.log(result.data);
            this.dependencies = result.data;
        } else if (result.error) {
            console.error(result.error);
        }
    }
}