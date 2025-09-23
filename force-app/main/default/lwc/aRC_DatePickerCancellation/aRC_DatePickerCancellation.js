import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';



const today = new Date();
const monthNames = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"];

export default class aRC_DatePickerCancellation extends OmniscriptBaseMixin(LightningElement) {

    @api reason;
    @api osData;
    @track maxEffDate;
    @track dateContext = new Date();
    @track selectedDate = new Date();
    @track dates = [];
    lastClass;
    isProgramChange = false;
    formattedSelectedDate = '';
    datePickerFirstOpened = false;
    
    get nextYear() {
        return today.getFullYear() + 1;    
    }
    get month() {
        return monthNames[this.dateContext.getMonth()];
    }

    updateInputValue(effDate) {
        if (effDate == '') {
            this.refreshDateNodes();
            this.formattedSelectedDate = '';
        } else{
            console.log(effDate);
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
            if ( this.dateContext.getDate() > 15 && !this.datePickerFirstOpened ) {
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
        // if (this.dateContext.getMonth() - 1 === today.getMonth() && this.dateContext.getFullYear() === today.getFullYear()) {
        //     const prevBtn = this.template.querySelector('.prev');
        //     if (prevBtn) {
        //         prevBtn.className = 'prevDis';
        //     }
        // }
        if (this.dateContext.getMonth() === today.getMonth() + this.maxEffDate) {
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
        this.dateContext = new Date(this.dateContext.getFullYear(), this.dateContext.getMonth() + 1, this.dateContext.getDate());
        const prevBtn = this.template.querySelector('.prevDis');
        if (prevBtn) {
            prevBtn.className = 'prev';
        }
        if (this.dateContext.getMonth() === today.getMonth() + this.maxEffDate) {
            const nextBtn = this.template.querySelector('.next');
            if (nextBtn) {
                nextBtn.className = 'nextDis';
            }
        }
        this.year = this.dateContext.getFullYear();
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
        if (this.isProgramChange) {
            if (this.reason == 'DATE_ProgramChangeEffectiveDate') this.omniUpdateDataJson({ 'DATE_SubscriberEffectiveDate': date});
            this.updateInputValue(date);
        }else{
            this.omniUpdateDataJson({ 'DATE_SubscriberEffectiveDate': date });
            this.updateInputValue(date);
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
                    let className = '';
                    if (JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('programChange')))) {
                        if (day.getDate() === parseInt(JSON.parse(JSON.stringify(this.omniJsonData.newEffectiveDate.split('-').pop()))) && day.getTime() >= this.effectiveDate.getTime()) {
                            if (day.getTime() === this.selectedDate.getTime()) {
                                className = 'selected';
                            } else {
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

            if(element.date.getDate() == todayNoTime.getDate() && (element.text == 1 || element.text == 15)){

                element.className = 'date'
            }
        });
        
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
        this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
		// 
		let effectiveDateSplit = this.omniJsonData.EffectiveDate.split('-');
		this.effectiveDate = new Date(effectiveDateSplit[0], effectiveDateSplit[1] - 1, effectiveDateSplit[2]);
        this.userProfile = this.osData.userProfile;
        if(this.userProfile == 'Member Community Profile'){
            this.maxEffDate = 3;
        } else {
            this.maxEffDate = 24;
        }

        this.refreshDateNodes();
		if(this.omniJsonData.EndDate){
        	this.populateInput();       
		}
    }

    populateInput(){
        if (JSON.parse(JSON.stringify(this.omniJsonData.hasOwnProperty('programChange')))) {
            this.isProgramChange = true;
            let effectiveDate = this.omniJsonData.EffectiveDate != null? this.omniJsonData.EffectiveDate :'';
			function getKeys(obj) {
                return Object.keys(obj).reduce((r, k) => {
                  r.push(k);
              
                  if(Object(obj[k]) === obj[k])
                    r.push(...getKeys(obj[k]));
              
                  return r;
                }, [])
            }
            this.dateContext = new Date(effectiveDate);
            this.year = this.dateContext.getFullYear();
            const checkDATE_ProgramChangeEffectiveDate = element => element == 'DATE_ProgramChangeEffectiveDate';
			if(this.reason == 'DATE_ProgramChangeEffectiveDate' && !getKeys(this.omniJsonData).some(checkDATE_ProgramChangeEffectiveDate)){
				this.omniUpdateDataJson({ 'DATE_SubscriberEffectiveDate': this.omniJsonData.newEffectiveDate});
			}

            this.updateInputValue(effectiveDate);
        }
    }

    renderedCallback(){
        const prevBtn = this.template.querySelector('[data-id="prevBtn"]');
        const nextBtn = this.template.querySelector('[data-id="nextBtn"]');

        if (this.formattedSelectedDate) this.template.querySelector('.selectedInput').className = 'vlocity-input nds-input nds-input_mask nds-not-empty nds-is-dirty selectedInput';
        if (this.isProgramChange) {
            let startingEffectiveDateSplit = this.omniJsonData.startingEffectiveDate.split('-');
            let minEffDate = new Date(startingEffectiveDateSplit[0], startingEffectiveDateSplit[1], startingEffectiveDateSplit[2]);
            //Remove this line below before go to Production
            // minEffDate.setHours(minEffDate.getHours() + 6);

            minEffDate.setHours(0, 0, 0, 0);
            const maxEffDate = new Date(today.getFullYear(), today.getMonth() + this.maxEffDate, 0);
            let dateContext = new Date(this.dateContext);
            dateContext.setHours(0, 0, 0, 0)

            // dateContext > minEffDate ? prevBtn.className = 'prev' : prevBtn.className = 'prevDis';
            dateContext > maxEffDate ? nextBtn.className = 'nextDis' : nextBtn.className = 'next';
        }else{
            const minEffDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);
            const maxEffDate = new Date(today.getFullYear(), today.getMonth() + this.maxEffDate, 0);
            const dateContext = new Date(this.dateContext).setHours(0, 0, 0, 0);

            // dateContext > minEffDate ? prevBtn.className = 'prev' : prevBtn.className = 'prevDis';
            dateContext > maxEffDate ? nextBtn.className = 'nextDis' : nextBtn.className = 'next';
        }
    }
}