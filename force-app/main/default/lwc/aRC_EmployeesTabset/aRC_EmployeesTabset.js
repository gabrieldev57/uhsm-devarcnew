import { LightningElement,api } from 'lwc';

export default class ARC_EmployeesTabset extends LightningElement {
    @api activeValue;
    @api tabs = [];
    renderedCallbackReady = false;
    renderedCallback() {
        if(this.renderedCallbackReady) return;
        this.renderedCallbackReady = true;
        this.registerTabs();
    }

    registerTabs() {
        this.tabs = Array.from(this.template.querySelector('slot')
            .assignedElements())
            .map(tab => ({
                label: tab.label,
                value: tab.value,
                headerClass: `tab-item ${tab.value === this.activeValue ? 'active' : ''}`
            }));
            console.log('Registered tabs:', this.tabs);
        
        this.updateTabVisibility();
    }

    // handleTabClick(event) {
    //     const selectedValue = event.currentTarget.dataset.value;
    //     this.activeValue = selectedValue;
    //     this.updateTabVisibility();
    // }
    handleTabClick(event) {
        const selectedValue = event.currentTarget.dataset.value;
        this.activeValue = selectedValue;
        this.updateTabVisibility();
        
        this.dispatchEvent(new CustomEvent('tabchange', {
            detail: { value: selectedValue }
        }));
    }

    updateTabVisibility() {
        const tabs = this.template.querySelector('slot').assignedElements();
        tabs.forEach(tab => {
            tab.active = tab.value === this.activeValue;
        });
        
        this.tabs = this.tabs.map(tab => ({
            ...tab,
            headerClass: `tab-item ${tab.value === this.activeValue ? 'active' : ''}`
        }));
    }
}