import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllData from '@salesforce/apex/ARC_AggregatorsChartController.getAllData';

export default class ARC_AggregatorsChart extends NavigationMixin(LightningElement) {
    @api recordId;
    @track data;
    @track family = [];
    @track familyDisplay = [];
    @track hasFamilyAgg = true;
    @track members = [];
    @track membersLongTerm = [];
    @track visits = [];
    @track visitsLongTerm = [];
    @track membersp = [];
    @track membersLongTermP = [];
    @track visitsp = [];
    @track visitsLongTermP = [];
    @track value;
    @track people = [];
    @track options = [];
    @track peopleFil = [];
    @track mem = [];
    @track selected = false;
    activePolicy = true;
    @track isAccount = false;
    @track activePolicyAccount = false;
    currentYear;
    @track clmYear;
    @track yearOptions = [];
    @track theresMembLT = false;
    @track theresVisLT = false;

    connectedCallback() {
        this.currentYear = new Date().getFullYear().toString();
        this.yearOptions.push({ label: this.currentYear, value: this.currentYear, id: this.currentYear });
        this.yearValue = this.currentYear;
        this.getApexData('connectedCallback');

    }

    getApexData(method) {
        this.familyDisplay = [];
        this.family = [];
        this.members = [];
        this.membersLongTerm = [];
        this.visits = [];
        this.visitsLongTerm = [];
        getAllData({ recordId: this.recordId })
            .then(response => {
                if (response.aggregators) {
                    if (response.accountPolicy != null) {
                        this.isAccount = true;
                        if (response.accountPolicy == 'isActive') this.activePolicyAccount = true;
                    } else if (method == 'connectedCallback' && response.clmYear != null) {
                        this.yearValue = response.clmYear.toString();
                    }
                    this.data = response.aggregators;
                    let i = 0;
                    this.data.forEach(element => {
                        element.currentPercent = 100 * element.ARC_CurrentValue__c / element.ARC_LimitValue__c;
                        element.limit = element.ARC_LimitValue__c;
                        element.nolimit = parseFloat(element.ARC_LimitValue__c) >= 1000000;
                        element.current = element.ARC_CurrentValue__c;
                        element.year = element.ARC_Year__c;

                        if (!this.yearOptions.some(y => y.id == element.year) && element.year != null) {
                            this.yearOptions.push({ label: element.year, value: element.year, id: element.year });
                        }
                        if (!element.Name.includes("Family") && !(element.RecordType.Name == 'Family')) {
                            element.memberName = element.ARC_Member__r.Name;
                            element.memberRole = element.ARC_Member__r.ARC_DependentRelationship__c == null ? 'Primary' : element.ARC_Member__r.ARC_DependentRelationship__c;
                            if (!this.mem.some(mem => mem.id == element.ARC_Member__c)) {
                                this.mem.push({ name: element.memberName, role: element.memberRole, id: element.ARC_Member__c })
                            }
                            if (element.ARC_Type__c == 'Currency') {
                                if (element.ARC_NextAvailabilityDate__c == null && element.ARC_Year__c != null) {

                                    // PRE-EXISTING AGGREGATOR, ALL BENEFIT YEARS
                                    if (element.ARC_Code__c == 'PREEX__c') this.generatePreExistingBY(element, this.members);
                                    else this.members.push(element);

                                    this.membersp = this.members;
                                } else {
                                    this.membersLongTerm.push(element);
                                    this.membersLongTermP = this.membersLongTerm;
                                }
                            } else if (element.ARC_Type__c == 'Number') {
                                if (element.ARC_NextAvailabilityDate__c == null && element.ARC_Year__c != null) {
                                    this.visits.push(element);
                                    this.visitsp = this.visits;
                                } else {
                                    element.isAvailable = element.ARC_LimitValue__c > element.ARC_CurrentValue__c;
                                    this.visitsLongTerm.push(element);
                                    this.visitsLongTermP = this.visitsLongTerm;
                                }
                            }
                        }
                        else if (element.Name.includes("Family") && element.RecordType.Name == 'Family') {
                            element.memberName = "Family";
                            element.current = element.ARC_FamilyCurrentValue__c;
                            element.remaining = element.ARC_LimitValue__c - element.ARC_FamilyCurrentValue__c;
                            element.currentPercent = 100 * element.ARC_FamilyCurrentValue__c / element.ARC_LimitValue__c;
                            this.family.push(element);

                        }
                    });
                    console.log(JSON.parse(JSON.stringify(this.members)));


                    this.mem.forEach((elementi) => {
                        this.people.push({ label: (elementi.name + ' - ' + elementi.role), value: elementi.id });
                    });
                    this.options = this.people;
                    this.yearOptions = [...this.yearOptions]; // Force rerender by creating a new array
                    var families = [];
                    this.family.forEach(element => {
                        if (element.year == this.yearValue) {
                            families.push(element);
                        }
                    });
                    this.familyDisplay = families;
                    if (response.object == 'Account') {
                        this.value = this.recordId;
                        this.selected = true;
                    } else if (response.object == 'Claim') {
                        this.value = response.clmAccount;
                        this.selected = true;
                    }
                } else {
                    this.activePolicy = false;
                }
                this.familyDisplay.length == 0 ? this.hasFamilyAgg = false : this.hasFamilyAgg = true;
                this.populateMember();
            })
            .catch(error => {
                console.error(error);
            })

    }

    handleChange(event) {
        this.value = event.detail.value;
        this.memberSelected();
        this.populateMember();
    }

    handleYearChange(event) {
        this.yearValue = event.detail.value;
        this.getApexData('handleYearChange');
    }

    memberSelected() {
        this.selected = true;
    }

    populateMember() {

        var families = [];
        this.family.forEach(element => {
            if (element.year == this.yearValue || element.year == null) {
                families.push(element);
            }
        });
        this.familyDisplay = families.map(item => ({ ...item, onClick: () => this.navigateToAggregatorRecord(item.Id) }));

        var membs = [];
        this.membersp.forEach(element => {
            if (element.ARC_Member__c == this.value && (element.year == this.yearValue || element.year == null)) {
                membs.push(element);
            }
        });
        this.members = membs.map(item => ({ ...item, onClick: () => this.navigateToAggregatorRecord(item.Id) }));
        this.members.sort((a, b) => a.Name.localeCompare(b.Name));

        var membsLT = [];
        this.membersLongTermP.forEach(element => {
            if (element.ARC_Member__c == this.value && (element.year == this.yearValue || element.year == null)) {
                membsLT.push(element);
            }
        });
        this.membersLongTerm = membsLT.map(item => ({ ...item, onClick: () => this.navigateToAggregatorRecord(item.Id) }));
        this.membersLongTerm.sort((a, b) => a.Name.localeCompare(b.Name));

        var vis = [];
        this.visitsp.forEach(element => {
            if (element.ARC_Member__c == this.value && (element.year == this.yearValue || element.year == null)) {
                vis.push(element);
            }
        });
        this.visits = vis.map(item => ({ ...item, onClick: () => this.navigateToAggregatorRecord(item.Id) }));
        this.visits.sort((a, b) => a.Name.localeCompare(b.Name));

        var visLT = [];
        this.visitsLongTermP.forEach(element => {
            if (element.ARC_Member__c == this.value && (element.year == this.yearValue || element.year == null)) {
                visLT.push(element);
            }
        });
        this.visitsLongTerm = visLT.map(item => ({ ...item, onClick: () => this.navigateToAggregatorRecord(item.Id) }));
        this.visitsLongTerm.sort((a, b) => a.Name.localeCompare(b.Name));
        this.membersLongTerm.length == 0 ? this.theresMembLT = false : this.theresMembLT = true;
        this.visitsLongTerm.length == 0 ? this.theresVisLT = false : this.theresVisLT = true;
    }

    navigateToAggregatorRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'ARC_Aggregator__c', // Replace with the API name of your object
                actionName: 'view'
            }
        });
    }

    // HELPER FUNCTIONS
    generatePreExistingBY(aggregator, list) {
        const benefitList = ['ARC_BY1_Date__c', 'ARC_BY2_Date__c', 'ARC_BY3_Date__c'].map((byDate, index) => {
            if (!aggregator[byDate]) return null;

            return {
                name: `Benefit Year ${index + 1}`,
                date: aggregator[byDate],
                limit: aggregator[`ARC_BY${index + 1}_Limit__c`],
                current: aggregator[`ARC_BY${index + 1}_Current__c`],
                styles: `width: ${100 * aggregator[`ARC_BY${index + 1}_Current__c`] / aggregator[`ARC_BY${index + 1}_Limit__c`]}%; border-radius: 15px; background: orange;`
            }
        }).filter(aggregator => aggregator != null);

        list.push({
            ...aggregator,
            benefitYear: benefitList
        })

        console.log(list);
    }
}