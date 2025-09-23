import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

const monthNames = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"];

export default class DatePickerPOC extends OmniscriptBaseMixin(LightningElement) {

    @api reason;
    @api osData;
    @track maxEffDate;
    @track dateContext = new Date();
    @track selectedDate = new Date();
    @track dates = [];
    lastClass;
    isProgramChange = false;
    isSpinOff = false;
    formattedSelectedDate;
    datePickerFirstOpened = false;

    get nextYear() {
        return this.today.getFullYear() + 1;
    }
    get month() {
        return monthNames[this.dateContext.getMonth()];
    }

    get today() {
        return new Date(new Date().setHours(0, 0, 0, 0));
    }

    updateInputValue(effDate) {
        console.log("effdate?" + JSON.stringify(effDate))
        if (effDate == '') {
            this.refreshDateNodes();
            this.formattedSelectedDate = '';
        } else {

            const selectedInput = this.template.querySelector('.selectedInput');
            if (selectedInput) selectedInput.className = 'vlocity-input nds-input nds-input_mask nds-not-empty nds-is-dirty selectedInput';
            let dateSplit = effDate.split('-');
            this.selectedDate = new Date(dateSplit[0], dateSplit[1] - 1, dateSplit[2]);
            this.refreshDateNodes();
            this.formattedSelectedDate = this.format(this.selectedDate, 'mm-dd-yyyy', 0, 0, 0);
        }
    }

    openDatePicker() {
        const datePicker = this.template.querySelector('.datesOutFocus');
        if (datePicker) {
            if (this.dateContext.getDate() > 15 && !this.datePickerFirstOpened) {
                this.datePickerFirstOpened = true;
                this.nextMonth();
            }
            datePicker.className = 'dates';
            datePicker.focus();
        }
    }

    closeDatePicker() {
        const datePicker = this.template.querySelector('.dates');
        if (datePicker) {
            datePicker.className = 'datesOutFocus';
        }
    }

    previousMonth() {
        if (this.dateContext.getMonth() - 1 === this.today.getMonth() && this.dateContext.getFullYear() === this.today.getFullYear()) {
            const prevBtn = this.template.querySelector('.prev');
            if (prevBtn) {
                prevBtn.className = 'prevDis';
            }
        }
        if (this.dateContext.getMonth() === this.today.getMonth() + this.maxEffDate) {
            const nextBtn = this.template.querySelector('.nextDis');
            if (nextBtn) {
                nextBtn.className = 'next';
            }
        }
        this.dateContext = new Date(this.dateContext.getFullYear(), this.dateContext.getMonth() - 1, this.dateContext.getDate());
        this.year = this.dateContext.getFullYear();
        this.refreshDateNodes();
    }

    nextMonth() {
        // this.dateContext = new Date(this.dateContext.getFullYear(), this.dateContext.getMonth() + 1, this.dateContext.getDate());
        // if (this.dateContext.getMonth() - tempDate.getMonth() > 1) {
        //     this.dateContext = new Date(tempDate.getFullYear(), tempDate.getMonth() + 1, 28);
        // }
        this.addMonths(1);
        console.log('this.dateContext =>', this.dateContext);
        const prevBtn = this.template.querySelector('.prevDis');
        if (prevBtn) {
            prevBtn.className = 'prev';
        }
        if (this.dateContext.getMonth() === this.today.getMonth() + this.maxEffDate) {
            const nextBtn = this.template.querySelector('.next');
            if (nextBtn) {
                nextBtn.className = 'nextDis';
            }
        }
        this.year = this.dateContext.getFullYear();
        this.refreshDateNodes();
    }

    addMonths(months) {
        let d = this.dateContext.getDate();
        this.dateContext.setMonth(this.dateContext.getMonth() + +months);
        if (this.dateContext.getDate() != d) {
            this.dateContext.setDate(0);
        }
        this.dateContext.setHours(0, 0, 0, 0);
    }

    @api
    setSelected(e) {
        this.closeDatePicker();
        const selectedDate = this.template.querySelector('.selected');
        const selectedInput = this.template.querySelector('.selectedInput');
        if (selectedInput) {
            selectedInput.className = 'nds-input nds-input_mask nds-not-empty nds-is-dirty selectedInput';
        }
        if (selectedDate) {
            selectedDate.className = this.lastClass;
        }
        const { date } = e.target.dataset;
        let dateSplit = date.split('-');
        this.selectedDate = new Date(dateSplit[0], dateSplit[1], dateSplit[2]);
        this.lastClass = e.target.className;
        e.target.className = 'selected';
        if (this.isProgramChange) {
            if (this.reason == 'remove') this.omniUpdateDataJson({ 'DATE_EffectiveDateRemoveMember': date });
            if (this.reason == 'upordowngrade') this.omniUpdateDataJson({ 'DATE_EffectiveDateUpgradeOrDowngrade': date });
            if (this.reason == 'upordowngrade') this.omniApplyCallResp({ 'upgrdDwngrd': date });
            if (this.reason == 'addmember') this.omniUpdateDataJson({ 'DATE_EffectiveDateAddMember': date });
            if (this.reason == 'review') this.omniUpdateDataJson({ 'DATE_EffectiveDateReview': date });
            if (this.reason == 'ancillary') this.omniUpdateDataJson({ 'DATE_EffectiveDateAncillary': date });
            if (this.reason == 'removeancillary') this.omniUpdateDataJson({ 'DATE_EffectiveDateRemoveAncillary': date });
            if (this.reason == 'DATE_ProgramChangeEffectiveDate') this.omniUpdateDataJson({ 'DATE_ProgramChangeEffectiveDateLWC': date });
            this.updateInputValue(date);
        } else if (this.isSpinOff) {
            this.omniUpdateDataJson({ 'DATE_SubscriberEffectiveDate': date });
            this.updateInputValue(date);
        } else {
            this.omniUpdateDataJson({ 'DATE_SubscriberEffectiveDate': date });
            this.updateInputValue(date);
        }

    }

    refreshDateNodes() {
	
        this.dates = [];
        
        let effectiveDate = this.osData?.SelectedContractInfo?.EffectiveDate ?? 'Not found';
        let dateOld = new Date(effectiveDate);
        console.log('Effective Date:', effectiveDate + 'dateOld: ' + dateOld.getDate());

        const firstSunday = this.getSundayFromWeekNum();
        for (let x = 0; x <= 4; x++) {
            Array(7)
                .fill(0)
                .forEach((n, i) => {

                    const day = new Date(new Date(firstSunday.getFullYear(), firstSunday.getMonth(), firstSunday.getDate() + n + i + (7 * x)).setHours(0, 0, 0, 0));
                    let className = '';
                    if (JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('programChange'))) || JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('SpinOffSelection')))) {
                        if (day >= this.today && (day.getDate() === parseInt(JSON.parse(JSON.stringify(this.omniJsonData.newEffectiveDate.split('-').pop()))))) {
                            if (day.getTime() === this.selectedDate.getTime()) {
                                className = 'selected';
                            } else {
                                className = 'date';
                            }
                        } else {
                            className = 'padder';
                        }
                    } else if (this.isLegacy == false || JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('datePickerProgramChange')))) {
                        console.log('day.getDate() =>', day.getDate());
                        console.log('dateOld.getDate() =>', dateOld.getDate());
                        if (day >= this.today && (day.getDate() === dateOld.getDate())) {
                            console.log('day >= this.today =>', day >= this.today);
                            if (day.getTime() === this.selectedDate.getTime()) {
                                console.log('day.getTime() === this.selectedDate.getTime() =>', day.getTime() === this.selectedDate.getTime());
                                className = 'selected';
                            } else if (day >= this.today) {
                                console.log('day >= this.today =>', day >= this.today);
                                className = 'date';
                            }
                        } else {
                            console.log('day >= this.today =>', day >= this.today);
                            className = 'padder';
                        }
                    } else if (this.isLegacy == true) {
												
                        const minStartDate = new Date(this.minimumStartDate);
                        console.log('minStartDate', minStartDate);
                        console.log('this.today =>', this.today);
                        console.log('day =>', day);
												
                        if (day >= minStartDate && day >= this.today && (day.getDate() === 1)) {
                            if (day.getTime() === this.selectedDate.getTime()) {
                                className = 'selected';
                            } else if (day >= this.today) {
                                className = 'date';
                            }
                        } else {
                            className = 'padder';
                        }
                    }
                    this.dates.push({
                        className,
                        date: day,
                        formatted: this.format(day, 'yyyy-mm-dd', 0, 0, 0),
                        text: String(day.getDate()).padStart(2, '0')
                    });
                });

        }

        let todayNoTime = new Date();
        todayNoTime.setHours(0, 0, 0, 0);

        this.dates.forEach(element => {

            if ((element.date.getDate() == todayNoTime.getDate() && (element.text == 1 || element.text == 15) && !(JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('programChange'))) || JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('SpinOffSelection')))))) {
                element.className = 'date'
            }

            if (JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('Assignments')))) {
                this.osData.Assignments.forEach (object => {
                    let listSize = object.ListSize;
                    let permissionSetName = object.PermissionSetName;
                    if (listSize == 1 && permissionSetName == 'Backdate_Effective_Date' && (element.text == 1 || element.text == 15)) {
                        element.className = 'date';
                    }
                    if (listSize == 1 && permissionSetName == 'Full_Permission_Effective_Date') {
                        element.className = 'date';
                    }
                })
            }
        });

    }


    getWeek(date) {
        var newYear = new Date(date.getFullYear(), 0, 1);
        var day = newYear.getDay();
        day = (day >= 0 ? day : day + 7);
        var daynum = Math.floor((date.getTime() - newYear.getTime() -
            (this.today.getTimezoneOffset() - newYear.getTimezoneOffset()) * 60000) / 86400000) + 1;
        var weeknum;
        if (day < 4) {
            weeknum = Math.floor((daynum + day - 1) / 7) + 1;
            if (weeknum > 52) {
                nYear = new Date(date.getFullYear() + 1, 0, 1);
                nday = nYear.getDay();
                nday = nday >= 0 ? nday : nday + 7;
                weeknum = nday < 4 ? 1 : 53;
            }
        }
        else {
            weeknum = Math.floor((daynum + day - 1) / 7);
        }
        return weeknum;
    };

    getSundayFromWeekNum() {
        let sunday = new Date(this.dateContext.getFullYear(), this.dateContext.getMonth(), 1);
        while (sunday.getDay() !== 0) {
            sunday.setDate(sunday.getDate() - 1);
        }
        return sunday;
    }

    format(date, format, addYears, addMonths, addDays) {
        var formatDate = new Date(date.getFullYear() + addYears, date.getMonth() + addMonths, date.getDate() + addDays);
        var dd = String(formatDate.getDate()).padStart(2, '0');
        var mm = String(formatDate.getMonth() + 1).padStart(2, '0');
        var yyyy = formatDate.getFullYear();
        const dateMap = new Map();
        dateMap.set('dd', dd);
        dateMap.set('mm', mm);
        dateMap.set('yyyy', yyyy);
        var formatSplit = [];
        if (format.includes('-')) {
            formatSplit = format.split('-')
            return dateMap.get(formatSplit[0]) + '-' + dateMap.get(formatSplit[1]) + '-' + dateMap.get(formatSplit[2]);
        } else {
            formatSplit = format.split('/')
            return dateMap.get(formatSplit[0]) + '/' + dateMap.get(formatSplit[1]) + '/' + dateMap.get(formatSplit[2]);
        }
    }

    connectedCallback() {
        console.log("this.today is: " + this.today)
        this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
				
				this.isLegacy = this.osData.isLegacy;
				console.log("Is Legacy?", this.isLegacy);
				
				this.minimumStartDate = this.osData.minimumStartDate;
				console.log("Minimum Start Date:", this.minimumStartDate);
				
        this.userProfile = this.osData.userProfile;
        if (this.userProfile == 'Member Community Profile') {
            this.maxEffDate = 3;
        } else {
            this.maxEffDate = 5;
        }

        this.refreshDateNodes();
        this.populateInput();
    }

    populateInput() {
				
				this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
				
        if (JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('programChange')))) {

            this.isProgramChange = true;

            // if(JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('SpinOffSelection')))){
            //     this.isSpinOff = true;
            // }

            let effectiveDate = this.omniJsonData.newEffectiveDate;
            function getKeys(obj) {
                return Object.keys(obj).reduce((r, k) => {
                    r.push(k);

                    if (Object(obj[k]) === obj[k])
                        r.push(...getKeys(obj[k]));

                    return r;
                }, [])
            }
            const checkRM = element => element == 'DATE_EffectiveDateRemoveMember';
            const checkUD = element => element == 'DATE_EffectiveDateUpgradeOrDowngrade';
            const checkAM = element => element == 'DATE_EffectiveDateAddMember';
            const checkReview = element => element == 'DATE_EffectiveDateReview';
            const checkAncillary = element => element == 'DATE_EffectiveDateAncillary';
            const checkRemoveAncillary = element => element == 'DATE_EffectiveDateRemoveAncillary';
            const checkDATE_ProgramChangeEffectiveDate = element => element == 'DATE_ProgramChangeEffectiveDate';
            if (this.reason == 'remove' && !getKeys(this.omniJsonData).some(checkRM)) {
                this.omniUpdateDataJson({ 'DATE_EffectiveDateRemoveMember': this.omniJsonData.newEffectiveDate });
            } else if (this.reason == 'remove' && getKeys(this.omniJsonData).some(checkRM)) {
                effectiveDate = this.omniJsonData.STEP_RemoveMember.LWC_RemoveMemberEffDate.DATE_EffectiveDateRemoveMember;
            } else if (this.reason == 'upordowngrade' && !getKeys(this.omniJsonData).some(checkUD)) {
                this.omniUpdateDataJson({ 'DATE_EffectiveDateUpgradeOrDowngrade': this.omniJsonData.newEffectiveDate });
                this.omniApplyCallResp({ 'upgrdDwngrd': this.omniJsonData.newEffectiveDate });

            } else if (this.reason == 'upordowngrade' && getKeys(this.omniJsonData).some(checkUD)) {
                effectiveDate = this.omniJsonData.STEP_DowngradeOrUpdatePlan.LWC_ProgramUpdateEffDate.DATE_EffectiveDateUpgradeOrDowngrade;
            } else if (this.reason == 'addmember' && !getKeys(this.omniJsonData).some(checkAM)) {
                this.omniUpdateDataJson({ 'DATE_EffectiveDateAddMember': this.omniJsonData.newEffectiveDate });
            } else if (this.reason == 'addmember' && getKeys(this.omniJsonData).some(checkAM)) {
                effectiveDate = this.omniJsonData.STEP_PrepareYourCensus.BLK_IFPProgramChangeCensus.LWC_DatePickerProgramChange.DATE_EffectiveDateAddMember;
            } else if (this.reason == 'review' && !getKeys(this.omniJsonData).some(checkReview)) {
                this.omniUpdateDataJson({ 'DATE_EffectiveDateReview': this.omniJsonData.newEffectiveDate });
            } else if (this.reason == 'review' && getKeys(this.omniJsonData).some(checkReview)) {
                effectiveDate = this.omniJsonData.STEP_PrepareYourCensus.BLK_IFPEnrollCensus.LWC_DatePickerShop.DATE_EffectiveDateReview;
            } else if (this.reason == 'ancillary' && !getKeys(this.omniJsonData).some(checkAncillary)) {
                this.omniUpdateDataJson({ 'DATE_EffectiveDateAncillary': this.omniJsonData.newEffectiveDate });
            } else if (this.reason == 'ancillary' && getKeys(this.omniJsonData).some(checkAncillary)) {
                effectiveDate = this.omniJsonData.STEP_SelectSMART.LWC_AddAncillaryEffDate.DATE_EffectiveDateAncillary;
            } else if (this.reason == 'removeancillary' && !getKeys(this.omniJsonData).some(checkRemoveAncillary)) {
                this.omniUpdateDataJson({ 'DATE_EffectiveDateRemoveAncillary': this.omniJsonData.newEffectiveDate });
            } else if (this.reason == 'removeancillary' && getKeys(this.omniJsonData).some(checkRemoveAncillary)) {
                effectiveDate = this.omniJsonData.DATE_ProgramChangeEffectiveDate;
            } else if (this.reason == 'DATE_ProgramChangeEffectiveDate' && !getKeys(this.omniJsonData).some(checkDATE_ProgramChangeEffectiveDate)) {
                this.omniUpdateDataJson({ 'DATE_ProgramChangeEffectiveDateLWC': this.omniJsonData.newEffectiveDate });
            } else if (this.reason == 'DATE_ProgramChangeEffectiveDate' && getKeys(this.omniJsonData).some(checkDATE_ProgramChangeEffectiveDate)) {
                effectiveDate = this.omniJsonData.DATE_ProgramChangeEffectiveDate;
            }
            this.dateContext = new Date(effectiveDate);
            //Remove this line below before go to Production
            // this.dateContext.setHours(this.dateContext.getHours() + 6);

            this.year = this.dateContext.getFullYear();

            this.updateInputValue(effectiveDate);
        } else {
            if (JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('SpinOffSelection')))) {
                this.omniUpdateDataJson({ 'DATE_ProgramChangeEffectiveDateLWC': this.omniJsonData.newEffectiveDate });
            }
            let effDate = '';
            JSON.parse(JSON.stringify(this.omniJsonData), function (key, value) {
                if (key == 'DATE_SubscriberEffectiveDate') {
                    effDate = value;
                }
            });
            if (effDate !== '') {
                this.dateContext = new Date(effDate);
            } else if (this.osData.isLegacy) {
							  this.dateContext = new Date(this.osData.minimumStartDate);
						} else {
                this.dateContext = this.today;
            }

            //Remove this line below before go to Production
            // this.dateContext.setHours(this.dateContext.getHours() + 6);

            this.year = this.dateContext.getFullYear();
            this.updateInputValue(effDate);
        }
    }

    renderedCallback() {
        const prevBtn = this.template.querySelector('[data-id="prevBtn"]');
        const nextBtn = this.template.querySelector('[data-id="nextBtn"]');

        if (this.formattedSelectedDate) this.template.querySelector('.selectedInput').className = 'vlocity-input nds-input nds-input_mask nds-not-empty nds-is-dirty selectedInput';
        if (this.isProgramChange || this.isSpinOff) {
            let minEffDate = new Date(this.omniJsonData.newEffectiveDate);
            //Remove this line below before go to Production
            // minEffDate.setHours(minEffDate.getHours() + 6);

            minEffDate.setHours(0, 0, 0, 0);
            const maxEffDate = new Date(minEffDate.getFullYear(), minEffDate.getMonth() + this.maxEffDate, 0);
            let dateContext = new Date(this.dateContext);
            dateContext.setHours(0, 0, 0, 0)

            dateContext > minEffDate ? prevBtn.className = 'prev' : prevBtn.className = 'prevDis';
            dateContext > maxEffDate ? nextBtn.className = 'nextDis' : nextBtn.className = 'next';
        } 
        else if (JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('Assignments')))) {
            this.osData.Assignments.forEach (object => {
                let listSize = object.ListSize;
                let permissionSetName = object.PermissionSetName;
                if (listSize == 1 && (permissionSetName == 'Backdate_Effective_Date' || permissionSetName == 'Full_Permission_Effective_Date')) {
                    const minEffDate = new Date(this.today.getFullYear(), this.today.getMonth() - this.maxEffDate, 0);
                    const maxEffDate = new Date(this.today.getFullYear(), this.today.getMonth() + this.maxEffDate, 0);
                    const dateContext = new Date(this.dateContext).setHours(0, 0, 0, 0);
    
                    dateContext > minEffDate ? prevBtn.className = 'prev' : prevBtn.className = 'prevDis';
                    dateContext > maxEffDate ? nextBtn.className = 'nextDis' : nextBtn.className = 'next';
                }
            })
        }
        else {
						const minEffDate = new Date(this.today.getFullYear(), this.today.getMonth() + 1, 0);
            const maxEffDate = new Date(this.today.getFullYear(), this.today.getMonth() + this.maxEffDate, 0);
            const dateContext = new Date(this.dateContext).setHours(0, 0, 0, 0);

            dateContext > minEffDate ? prevBtn.className = 'prev' : prevBtn.className = 'prevDis';
            dateContext > maxEffDate ? nextBtn.className = 'nextDis' : nextBtn.className = 'next';
        }
    }
}