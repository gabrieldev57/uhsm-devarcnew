import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAggregators from '@salesforce/apex/ARC_AggregatorsChartController.getAggregators';

export default class ARC_AggregatorsChartPOC extends NavigationMixin(LightningElement) {
    @api recordId;
    @track data;
    @track family = [];
    @track familyDisplay = [];
    @track hasFamilyAgg = true;
    @track members = [];
    @track membersPreEx = [];
    @track membersMat = [];
    @track membersLongTerm = [];
    @track visits = [];
    @track visitsLongTerm = [];
    @track membersp = [];
    @track membersPreExP = [];
    @track membersMatP = [];
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
    currentDateFormatted;
    @track clmYear;
    @track yearOptions = [];
    @track theresMembLT = false;
    @track theresVisLT = false;
    @track theresPreEx = false;
    @track theresMat = false;
    memberCoveragePeriod_PREEX = {}
    memberCoveragePeriod_MAT = {}
    memberHasFamilyMap = {};
    selectedMemberHasFamily = false;
    unitCodes = ['SPEINJ__c', 'STDINJ__c', 'NONINJ__c', 'GENINJ__c', 'SHINVAC__c'];

    connectedCallback() {
        let currentDate = new Date();
        this.currentDateFormatted = currentDate.getFullYear() + '/' + currentDate.getMonth() + '/' + currentDate.getDate()
        this.currentYear = currentDate.getFullYear().toString();
        this.getApexData('connectedCallback');
    }

    getApexData(method) {
        this.familyDisplay = [];
        this.family = [];
        this.members = [];
        this.membersLongTerm = [];
        this.membersPreEx = [];
        this.membersMat = [];
        this.visits = [];
        this.visitsLongTerm = [];
        getAggregators({ recordId: this.recordId })
            .then(response => {
                console.log('getAggregators response => ', response)
                if (response.aggregators) {
                    this.memberCoveragePeriod_PREEX = response.member_coverage_periods_preex;
                    this.memberCoveragePeriod_MAT = response.member_coverage_periods_mat;
                    this.memberHasFamilyMap = response.memberHasFamily;

                    if (response.accountPolicy != null) {
                        this.isAccount = true;
                        if (response.accountPolicy == 'isActive') this.activePolicyAccount = true;
                    } else if (method == 'connectedCallback' && response.clmYear != null) {
                        this.yearValue = response.clmYear.toString();
                    }

                    this.data = response.aggregators;
                    this.data.forEach(element => {
                        if (element.ARC_ConsumedTotal__c == null) element.ARC_ConsumedTotal__c = 0;
                        element.currentPercent = 100 * element.ARC_ConsumedTotal__c / element.ARC_LimitValue__c;
                        element.limit = element.ARC_LimitValue__c;
                        element.nolimit = parseFloat(element.ARC_LimitValue__c) >= 1000000;
                        element.current = element.ARC_ConsumedTotal__c;
                        element.year = element.ARC_Year__c;
                        element.startDate = element.ARC_StartDate__c;
                        element.endDate = element.ARC_EndDate__c;

                        if (!this.yearOptions.some(y => y.id == element.year) && element.year != null) {
                            this.yearOptions.push({ label: element.year, value: element.year, id: element.year });
                        }
                        if (!element?.Name?.includes("Family") && !(element?.RecordType?.Name == 'Family')) {
                            element.memberName = element.ARC_Member__r.Name;
                            element.memberRole = element.ARC_Member__r.ARC_DependentRelationship__c == null ? 'Primary' : element.ARC_Member__r.ARC_DependentRelationship__c;
                            if (!this.mem.some(mem => mem.id == element.ARC_Member__c)) {
                                this.mem.push({ name: element.memberName, role: element.memberRole, id: element.ARC_Member__c })
                            }
                            if (element.ARC_Type__c == 'Currency') {
                                if (element.ARC_NextAvailabilityDate__c == null && (element.ARC_Year__c != null || element.ARC_Code__c == 'PREEX__c' || element.ARC_Code__c == 'MAT__c')) {
                                    if (element.ARC_Code__c == 'PREEX__c' && element.ARC_Year__c == null) {
                                        this.membersPreEx.push(element);
                                        this.membersPreExP = this.membersPreEx;
                                    } else if (element.ARC_Code__c == 'PREEX__c' && element.ARC_Year__c != null) {
                                        this.generatePreExistingBY(element, this.members);
                                    } else if (element.ARC_Code__c == 'MAT__c' && element.ARC_Year__c == null) {
                                        this.membersMat.push(element);
                                        this.membersMatP = this.membersMat;
                                    } else {
                                        this.members.push(element);
                                        this.membersp = this.members;
                                    }
                                    
                                } else {
                                    // Add an identifier to display it as Currency instead of Visits
                                    element.isCurrency = true;
                                    this.membersLongTerm.push(element);
                                    this.membersLongTermP = this.membersLongTerm;
                                }
                            } else if (element.ARC_Type__c == 'Number') {

                                if (element.ARC_Code__c == 'SHINVAC__c') {
                                    // Add an identifier to display it as Visits instead of  Currency
                                    element.isUnit = true;
                                    this.membersLongTerm.push(element);
                                    this.membersLongTermP = this.membersLongTerm;
                                } else if (element.ARC_NextAvailabilityDate__c == null && element.ARC_Year__c != null) {
                                    if (this.unitCodes.includes(element.ARC_Code__c)) {
                                        element.isUnit = true;
                                    } else {
                                        element.isVisit = true;
                                    }
                                    this.visits.push(element);
                                    this.visitsp = this.visits;
                                } else {
                                    element.isAvailable = element.ARC_LimitValue__c > element.ARC_ConsumedTotal__c && element.ARC_NextAvailabilityDate__c < this.currentDateFormatted;
                                    this.visitsLongTerm.push(element);
                                    this.visitsLongTermP = this.visitsLongTerm;
                                }
                            }
                        }
                        else if (element?.Name?.includes("Family") && element?.RecordType?.Name == 'Family') {
                            element.memberName = "Family";
                            element.current = element.ARC_ConsumedTotal__c;
                            element.remaining = element.ARC_LimitValue__c - element.ARC_ConsumedTotal__c;
                            element.currentPercent = 100 * element.ARC_ConsumedTotal__c / element.ARC_LimitValue__c;
                            this.family.push(element);

                        }
                    });

                    this.mem.forEach((elementi) => {
                        this.people.push({ label: (elementi.name + ' - ' + elementi.role), value: elementi.id });
                    });
                    this.options = this.people;
                    this.yearOptions.sort((a, b) => b.value - a.value);
                    this.yearOptions = [...this.yearOptions]; // Force rerender by creating a new array
                    if (!this.yearValue) {
                        this.yearValue = this.yearOptions.length > 0
                                ? this.yearOptions[0].value.toString()
                                : null;
                    }
                    this.data.forEach(element => {
                        if (element.ARC_Code__c === 'CRITILL__c') {
                            element.monthlyBars = this.generateMonthlyBars(element);
                        }
                    });
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
                    if (this.value) {
                        this.selectedMemberHasFamily = this.memberHasFamilyMap?.[this.value] || false;
                    }
                } else {
                    this.activePolicy = false;
                }
                this.populateMember();
                this.mapCoveragePeriods = response.mapCoveragePeriods;
            })
            .catch(error => {
                console.error(error);
            })
    }

    handleChange(event) {
        this.value = event.detail.value;
        this.selectedMemberHasFamily = this.memberHasFamilyMap[this.value] || false;
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
        if (this.selectedMemberHasFamily) {
            this.family.forEach(element => {
                if (element.year == this.yearValue || element.year == null) {
                    families.push(element);
                }
            });
        }
        this.familyDisplay = families.map(item => ({ ...item, onClick: () => this.navigateToAggregatorRecord(item.Id) }));

        var membs = [];
        this.membersp.forEach(element => {
            if (element.ARC_Member__c == this.value && (element.year == this.yearValue || element.year == null)) {
                membs.push(element);
            }
        });
        this.members = membs.map(item => ({ ...item, onClick: () => this.navigateToAggregatorRecord(item.Id) }));
        this.members.sort((a, b) => a.Name.localeCompare(b.Name));

        // Pre-Existing Aggregators List
        var membsPreEx = [];
        this.membersPreExP.forEach(element => {
            if (element.ARC_Member__c == this.value && this.showPreExAggregator(element)) {
                membsPreEx.push(element);
            }
        });
        this.membersPreEx = membsPreEx.map(item => ({ ...item, onClick: () => this.navigateToAggregatorRecord(item.Id) }));
        this.membersPreEx.sort((a, b) => a.benefitYearName.localeCompare(b.benefitYearName));

        // Maternity Aggregators List
        var membsMat = [];
        this.membersMatP.forEach(element => {
            if (element.ARC_Member__c == this.value && this.showMatAggregator(element)) {
                membsMat.push(element);
            }
        });
        this.membersMat = membsMat.map(item => ({ ...item, onClick: () => this.navigateToAggregatorRecord(item.Id) }));
        this.membersMat.sort((a, b) => a.Name.localeCompare(b.Name));

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
        this.membersPreEx.length == 0 ? this.theresPreEx = false : this.theresPreEx = true;
        this.membersMat.length == 0 ? this.theresMat = false : this.theresMat = true;
        this.hasFamilyAgg = this.selectedMemberHasFamily && this.familyDisplay.length > 0;
        console.log('debug by gabriel this.membersPreex ---> ', JSON.parse(JSON.stringify(this.membersPreEx)))
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
    }

    showPreExAggregator(element) {
        // Years
        let aggregatorStartYear = Number(element.ARC_StartDate__c.split('-')[0]);
        let show = false;
        let memberPeriodsRaw = this.memberCoveragePeriod_PREEX[element.ARC_Member__c] || [];

        if (!memberPeriodsRaw.length) return false;

        let memberPeriods = memberPeriodsRaw.map(p => {
            return {
                startYear: Number((p.split('||')[0]).substring(0, 4)),
                endYear: Number((p.split('||')[1]).substring(0, 4)),
                benefitYear: p.split('||')[2]
            };
        });

        // Look for the Aggregator's period
        let periodIndex = memberPeriods.findIndex(period => period.startYear == aggregatorStartYear);
        console.log('showPreExAggregator: memberPeriods ---> ', memberPeriods)
        console.log('showPreExAggregator: periodIndex ---> ', periodIndex)
        console.log('showPreExAggregator: aggregatorStartYear ---> ', aggregatorStartYear)

        if (periodIndex != -1) {
            console.log('showPreExAggregator: periodIndex ---> ', periodIndex);
            console.log('showPreExAggregator: period ---> ', memberPeriods[periodIndex]);
            let period = memberPeriods[periodIndex];

            // Set the Aggregator's Benefit Year name
            const benefitYearNames = {'BY1': 'Benefit Year 1', 'BY2': 'Benefit Year 2', 'BY3': 'Benefit Year 3'}
            element.benefitYearName = benefitYearNames[period.benefitYear]

            if (period.startYear == aggregatorStartYear && (period.startYear == this.yearValue || period.endYear == this.yearValue)) {
                show = true;
            } else {
                if (period.benefitYear == 'BY1') {
                    // Verify if next period is in the range of the year selected
                    const next1 = memberPeriods[periodIndex + 1];
                    const next2 = memberPeriods[periodIndex + 2];
                    if (
                        (next1 && (next1.startYear == this.yearValue || next1.endYear == this.yearValue)) ||
                        (next2 && (next2.startYear == this.yearValue || next2.endYear == this.yearValue))
                    ) {
                        show = true;
                        console.log('showPreExAggregator: show extra BY1')
                    }
                } else if (period.benefitYear == 'BY2') {
                    // Verify if next period is in the range of the year selected
                    const next1 = memberPeriods[periodIndex + 1];
                    if (next1 && (next1.startYear == this.yearValue || next1.endYear == this.yearValue)) {
                        show = true;
                        console.log('showPreExAggregator: show extra BY2')
                    }
                }
            }
        }
        return show;
    }

    showMatAggregator(element) {
        // Years
        let startDateYear = new Date(element.ARC_StartDate__c).getFullYear();
        let endDateYear = element.ARC_EndDate__c != '' ? new Date(element.ARC_EndDate__c).getFullYear() : Date.today();
        let show = false;

        let memberPeriods = this.memberCoveragePeriod_MAT[element.ARC_Member__c];

        memberPeriods.forEach(period => {
            let startPeriodYear = new Date(period.split('||')[0]).getFullYear();

            if (startDateYear == startPeriodYear && startPeriodYear <= this.yearValue && endDateYear >= this.yearValue) {
                show = true;
            }
        })

        return show;
    }

    generateMonthlyBars(element) {
        const year = Number(this.yearValue);
        const months = [];
        const children = (element.ComponentAggregators__r || [])
            .filter(c => Number(c.ARC_Year__c) === year);
        const monthMap = {};

        children.forEach(child => {
            const month = Number(child.ARC_StartDate__c.split('-')[1]) - 1;
            monthMap[month] = child;
        });

        for (let i = 0; i < 12; i++) {
            const existing = monthMap[i];
            if (existing) {
                const current = existing.ARC_ConsumedTotal__c || 0;
                const limit = existing.ARC_LimitValue__c || 1000;
                const percent = (current / limit) * 100;
                months.push({
                    month: i,
                    label: new Date(year, i).toLocaleString('en-US', { month: 'long' }),
                    current: current,
                    limit: limit,
                    percent: percent
                });
            } else {
                months.push({
                    month: i,
                    label: new Date(year, i).toLocaleString('en-US', { month: 'long' }),
                    current: 0,
                    limit: 1000,
                    percent: 0
                });
            }
        }

        return months;
    }
}