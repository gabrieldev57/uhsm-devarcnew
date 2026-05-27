import { LightningElement, wire, track, api } from 'lwc';
import getPortalMatrixForCurrentUser
    from '@salesforce/apex/aRC_employerPortalMatrixController.getPortalMatrixForCurrentUser';

export default class aRC_employerPortalMatrix extends LightningElement {
    @api recordId;
    @track groupClasses = [];
    activeSections = [];
    hasData = false;
    error;


    toggleGroupClass(event) {

        const id = event.currentTarget.dataset.id;

        this.groupClasses = this.groupClasses.map(gc => {

            if (gc.id === id) {

                const open = !gc.open;

                return {
                    ...gc,
                    open: open,
                    chevronClass: open ? 'chevron up' : 'chevron'
                };
            }

            return gc;
        });
    }

    @wire(getPortalMatrixForCurrentUser)
    wiredMatrix({ data, error }) {
        if (data) {
            const processed = data.map(gc => {
                const rows = (gc.rows || []).map((r, index) => {
                    return {
                        ...r,
                        rowKey: `${gc.id}-${index}`
                    };
                });

                return {
                    id: gc.id,
                    name: gc.name,
                    employeeType: gc.employeeType,
                    employeeDivision: gc.employeeDivision,
                    hasContributions: gc.hasContributions,
                    rows: rows,
                    open: true,
                    chevronClass: 'chevron chevron-down'
                };
            });

            this.groupClasses = processed;
            console.log('raw data:', data);
            console.log('processed group classes:', this.groupClasses);
            console.log('hasData:', this.hasData);
            this.hasData = processed.some(gc => gc.rows && gc.rows.length > 0);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            console.log('error:', error);
            this.groupClasses = [];
            this.hasData = false;
        }
    }

    get hasGroupClasses() {
        return this.groupClasses && this.groupClasses.length > 0;
    }
}