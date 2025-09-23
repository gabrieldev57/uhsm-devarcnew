import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

const today = new Date();
const monthNames = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"];

export default class DateOfBirth extends OmniscriptBaseMixin(LightningElement) {
    @api jsondata;
    @api formattedSelectedDate = '';
    @api ischild;
    @api valueparent;
    @track dateContext = new Date();
    @track selectedDate = new Date();
    @track dates = [];
    lastClass;
    years = [];
    isYearSelected = false;
    yearSelected;
    prevBtnClass = 'prev';
    nextBtnClass = 'next';

    get year() {
        return today.getFullYear();
    }
    get nextYear() {
        return today.getFullYear() + 1;    
    }
    get month() {
        return monthNames[this.dateContext.getMonth()];
    }

    openDatePicker() {
        const datePicker = this.template.querySelector('.datesOutFocus');
        if (datePicker) {
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
        if (this.dateContext.getMonth() == 1) {
            this.dateContext = new Date(this.dateContext.getFullYear(), this.dateContext.getMonth() - 1, this.dateContext.getDate());
            this.prevBtnClass = 'prevDis';
        } else{
            this.dateContext = new Date(this.dateContext.getFullYear(), this.dateContext.getMonth() - 1, this.dateContext.getDate());
            if(this.nextBtnClass == 'nextDis') this.nextBtnClass = 'next';
        }
        this.refreshDateNodes();
    }

    nextMonth() {
        if (this.dateContext.getMonth() == 10) {
            this.dateContext = new Date(this.dateContext.getFullYear(), this.dateContext.getMonth() + 1, this.dateContext.getDate());
            this.nextBtnClass = 'nextDis';
        } else{
            this.dateContext = new Date(this.dateContext.getFullYear(), this.dateContext.getMonth() + 1, this.dateContext.getDate());
            if(this.prevBtnClass == 'prevDis') this.prevBtnClass = 'prev';
        }
        this.refreshDateNodes();
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
        if (this.ischild) {
            this.updateInputValue(null, date);
            
            const eventToParent = new CustomEvent("datechanged", {detail: date})
            this.dispatchEvent(eventToParent);
        }else{
            this.updateInputValue(this.omniJsonData, date);
            this.omniUpdateDataJson({ 'DATE_DateOfBirth': date });
        }
    }

    updateInputValue(data, dateValue){
        if (dateValue) {
            let dateSplit = dateValue.split('-');
            this.selectedDate = new Date(dateSplit[0], dateSplit[1] - 1, dateSplit[2]);
            this.formattedSelectedDate = this.selectedDate.toLocaleDateString();
        }else{
            let dateOfBirth = null;
            JSON.parse(JSON.stringify(data), function (key, value) {
                if (key == 'DATE_DateOfBirth') {
                    dateOfBirth = value;
                }
            });
            if (dateOfBirth) {
                const selectedInput = this.template.querySelector('.selectedInput');
                if (selectedInput) selectedInput.className = 'vlocity-input nds-input nds-input_mask nds-not-empty nds-is-dirty selectedInput';
                let dateSplit = dateOfBirth.split('-');
                this.selectedDate = new Date(dateSplit[0], dateSplit[1] - 1, dateSplit[2]);
                this.formattedSelectedDate = this.selectedDate.toLocaleDateString();;
            }else{
                this.formattedSelectedDate = '';
            }
        }
    }

    refreshDateNodes() {
        this.dates = [];
        const firstSunday = this.getSundayFromWeekNum();
        for (let x = 0; x <= 4; x++) {
            Array(7)
                .fill(0)
                .forEach((n, i) => {
                    const day = new Date(firstSunday.getFullYear(), firstSunday.getMonth(), firstSunday.getDate() + n + i + (7 * x));
                    let className;
                    if (this.dateContext.getMonth() == day.getMonth() && day < today) {
                        className = 'date';
                    }else{
                        className = 'padder';
                    }
                    this.dates.push({
                        className,
                        formatted: this.format(day, 'yyyy-mm-dd', 0, 0, 0),
                        text: String(day.getDate()).padStart(2, '0')
                    });
                });
        }
    }

    getWeek(date) {
        var newYear = new Date(date.getFullYear(), 0, 1);
        var day = newYear.getDay();
        day = (day >= 0 ? day : day + 7);
        var daynum = Math.floor((date.getTime() - newYear.getTime() -
            (today.getTimezoneOffset() - newYear.getTimezoneOffset()) * 60000) / 86400000) + 1;
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
        var sunday = new Date(this.yearSelected, this.dateContext.getMonth(), 1);
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

    loadYears(){
        const currentYear = new Date().getFullYear();
        for (let i = 0; i < 120; i++) {
            let prev = currentYear - i;
            this.years.push(prev);
        }
    }

    handleYearSelected(evt){
        this.isYearSelected = true;
        if(this.dateContext.getMonth() == 0) this.prevBtnClass = 'prevDis';
        if(this.dateContext.getMonth() == 11) this.nextBtnClass = 'nextDis';
        this.yearSelected = evt.currentTarget.dataset.year;
        this.dateContext.setFullYear(this.yearSelected);
        this.refreshDateNodes();
    }

    handleSelectYearAgain(){
        this.isYearSelected = false;
    }

    connectedCallback() {
        this.loadYears();
        if(this.omniJsonData){
            this.updateInputValue(this.omniJsonData, null);
        }else{
            this.updateInputValue(null, this.valueparent);
        }
    }

    renderedCallback(){
        if (!this.omniJsonData && this.valueparent || this.formattedSelectedDate !== '') {
            const selectedInput = this.template.querySelector('.selectedInput');
            selectedInput.className = 'vlocity-input nds-input nds-input_mask nds-not-empty nds-is-dirty selectedInput';
        }
    }
}