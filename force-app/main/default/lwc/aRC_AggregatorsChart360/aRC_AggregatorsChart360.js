import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAggregators from '@salesforce/apex/ARC_AggregatorsChartController.getAggregators360';

export default class ARC_AggregatorsChart360 extends NavigationMixin(LightningElement) {
    @api recordId;

    // Date filters (used in HTML)
    @api inputFromDate = new Date().toISOString().split('T')[0];;
    @api inputToDate = new Date().toISOString().split('T')[0];;

    // Display collections (used in HTML)
    family = [];
    familyDisplay = [];
    members = [];
    membersPreEx = [];
    membersMat = [];
    membersLongTerm = [];
    visits = [];
    visitsLongTerm = [];

    // Persistent copies for filtering
    membersp = [];
    membersPreExP = [];
    membersMatP = [];
    membersLongTermP = [];
    visitsp = [];
    visitsLongTermP = [];

    // UI flags (used in HTML)
    hasFamilyAgg = true;
    theresMembLT = false;
    theresVisLT = false;
    theresPreEx = false;
    theresMat = false;

    // Helpers
    currentDateFormatted;
    memberCoveragePeriod_PREEX = {};
    memberCoveragePeriod_MAT = {};
    unitCodes = ['SPEINJ__c', 'STDINJ__c', 'NONINJ__c', 'GENINJ__c', 'SHINVAC__c'];
    benefitYearNames = {'BY1': 'Benefit Year 1', 'BY2': 'Benefit Year 2', 'BY3': 'Benefit Year 3'};

    enableDebug = true;

    connectedCallback() {
        const now = new Date();
        this.currentDateFormatted =
            `${now.getFullYear()}/${now.getMonth()}/${now.getDate()}`;
        this.getApexData('connectedCallback');
    }

    getApexData(method) {
        this.resetCollections();

        getAggregators({ recordId: this.recordId })
            .then(response => {
                console.log('chart 360 response=> ', response)
                if(method == 'connectedCallback'){
                    if(response?.defaultFromDate != null) {
                        this.inputFromDate = response.defaultFromDate;
                        this.inputToDate = response.defaultFromDate;
                    }
                }

                if (!response?.aggregators) return;

                this.memberCoveragePeriod_PREEX = response.member_coverage_periods_preex || {};
                this.memberCoveragePeriod_MAT = response.member_coverage_periods_mat || {};

                response.aggregators.forEach(element => {
                    this.normalizeAggregator(element);
                    this.routeAggregator(element);
                });

                this.filterAggregators();
            })
            .catch(error => {
                // eslint-disable-next-line no-console
                console.error(error);
            });
    }

    resetCollections() {
        this.family = [];
        this.familyDisplay = [];
        this.members = [];
        this.membersPreEx = [];
        this.membersMat = [];
        this.membersLongTerm = [];
        this.visits = [];
        this.visitsLongTerm = [];

        this.membersp = [];
        this.membersPreExP = [];
        this.membersMatP = [];
        this.membersLongTermP = [];
        this.visitsp = [];
        this.visitsLongTermP = [];
    }

    normalizeAggregator(element) {
        element.current = element.ARC_ConsumedTotal__c ?? 0;
        element.limit = element.ARC_LimitValue__c;
        element.nolimit = Number(element.limit) >= 1_000_000;
        element.currentPercent = (element.current / element.limit) * 100;
        element.year = element.ARC_Year__c;
        element.benefitYear = element.ARC_BenefitYear__c;
        element.startDate = element.ARC_StartDate__c;
        element.endDate = element.ARC_EndDate__c;
        element.benefitYearName = this.benefitYearNames[element?.benefitYear]; 
        if (element.ARC_Code__c === 'CRITILL__c') {
            element.monthlyBars = this.generateMonthlyBarsRange(
                this.inputFromDate,
                this.inputToDate,
                element.ComponentAggregators__r
            );
        }
    }

    routeAggregator(element) {
        // Family
        if (element?.RecordType?.Name === 'Family') {
            this.family.push(element);
            return;
        }

        // Currency aggregators
        if (element.ARC_Type__c === 'Currency') {
            if (element.ARC_NextAvailabilityDate__c == null && (element.ARC_Year__c != null || element.ARC_Code__c == 'PREEX__c' || element.ARC_Code__c == 'MAT__c')) {
                if (element.ARC_Code__c == 'PREEX__c') {

                    this.membersPreEx.push(element);
                    this.membersPreExP = this.membersPreEx;
                } else if (element.ARC_Code__c == 'MAT__c') {
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
        }

        // Number aggregators
        if (element.ARC_Type__c === 'Number') {
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
                element.isAvailable = element.limit > element.current && element.ARC_NextAvailabilityDate__c < this.currentDateFormatted;
                console.log(element.Name , element.limit)
                console.log(element.Name , element.current)
                console.log(element.Name , element.ARC_NextAvailabilityDate__c)
                console.log(element.Name , element.currentDateFormatted)
                this.visitsLongTerm.push(element);
                this.visitsLongTermP = this.visitsLongTerm;
            }
        }
    }

    handleDateChange(event) {
        // this[event.target.name === 'fromDate' ? 'inputFromDate' : 'inputToDate'] =
        //     event.target.value;
        const { name, value } = event.target;

        if (name === 'fromDate') {
            this.inputFromDate = value;

            if (this.inputToDate && value > this.inputToDate) {
                this.inputToDate = value;
            }
        } else {
            this.inputToDate = value;

            if (this.inputFromDate && value < this.inputFromDate) {
                this.inputFromDate = value;
            }
        }
        this.recalculateMonthlyBars();
        this.filterAggregators();
    }

    filterAggregators() {
        this.familyDisplay = this.filterAndDecorate(this.family);
        this.members = this.filterAndDecorate(this.membersp);
        this.membersPreEx = this.filterAndDecorate(this.membersPreExP);
        this.membersMat = this.filterAndDecorate(this.membersMatP);
        this.membersLongTerm = this.filterAndDecorate(this.membersLongTermP);
        this.visits = this.filterAndDecorate(this.visitsp);
        this.visitsLongTerm = this.filterAndDecorate(this.visitsLongTermP);

        this.hasFamilyAgg = this.familyDisplay.length > 0;
        this.theresMembLT = this.membersLongTerm.length > 0;
        this.theresVisLT = this.visitsLongTerm.length > 0;
        this.theresPreEx = this.membersPreEx.length > 0;
        this.theresMat = this.membersMat.length > 0;
    }

    filterAndDecorate(list) {
        return list
            .filter(el => this.filterSingleAggregator(el))
            .map(item => ({
                ...item,
                onClick: () => this.navigateToAggregatorRecord(item.Id)
            }))
            .sort((a, b) => a.startDate?.localeCompare(b.startDate || '') || 0)
            .sort((a, b) => a.Name?.localeCompare(b.Name || '') || 0);
    }

    filterSingleAggregator(element) {
        if (!element.startDate) return false;

        if (element.endDate) {
            return (
                element.startDate <= this.inputToDate &&
                element.endDate >= this.inputFromDate
            );
        }

        return element.startDate <= this.inputToDate;
    }

    navigateToAggregatorRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'ARC_Aggregator__c',
                actionName: 'view'
            }
        });
    }

    generateMonthlyBarsRange(fromDate, toDate, components = []) {
        if (!fromDate || !toDate) return [];

        const start = new Date(fromDate);
        const end = new Date(toDate);

        const bars = [];
        const current = new Date(start.getFullYear(), start.getMonth(), 1);

        while (current <= end) {
            const year = current.getFullYear();
            const month = current.getMonth();

            const component = components.find(c => {
                if (!c.ARC_StartDate__c) return false;
                const cmonth = Number(c.ARC_StartDate__c.split('-')[1]) - 1;
                const cyear = Number(c.ARC_Year__c);
                return cyear === year && cmonth === month;
            });

            const consumed = component?.ARC_ConsumedTotal__c ?? 0;
            const limit = component?.ARC_LimitValue__c ?? 1000;
            const percent = (consumed / limit) * 100;
            const monthName = new Date(year, month).toLocaleString('en-US', { month: 'long' });
            const label = year + ' ' + monthName;

            bars.push({
                label,
                current: consumed,
                limit,
                percent
            });

            current.setMonth(current.getMonth() + 1);
        }

        return bars;
    }

    recalculateMonthlyBars() {
        this.membersLongTermP.forEach(el => {
            if (
                el.ARC_Code__c === 'CRITILL__c' &&
                el.ComponentAggregators__r
            ) {
                el.monthlyBars = this.generateMonthlyBarsRange(
                    this.inputFromDate,
                    this.inputToDate,
                    el.ComponentAggregators__r
                );
            }
        });
    }
}