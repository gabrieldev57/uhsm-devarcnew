public class AgeUpUtilityClass {
    /**
     * Checks if a person has a birthday anniversary between the effective date and the effective date + 60
     * The function calculates the next birthday date for the person based on the birth date,
     * and then compares it with the effective date and effective date plus 60 days.
     *
     * @param birthDate The birth date of the person.
     * @param effectiveDate The effective date for comparison.
     * @return Boolean value indicating whether the person has a birthday anniversary between
     *         the birth date and the effective date.
     */
    public static Boolean hasBirthdayAnniversary(Date birthDate, Date effectiveDate) {
        // Calculate the birthday anniversary date for the effective year
        Date birthDayEffectiveYear = Date.newInstance(effectiveDate.year(), birthDate.month(), birthDate.day());
    
        // Calculate the date 60 days after the effective date
        Date effectiveDatePlus60 = effectiveDate.addDays(60);
    
        // Check if the birthday anniversary falls within the 60-day range
        return birthDayEffectiveYear >= effectiveDate && birthDayEffectiveYear < effectiveDatePlus60;
    }
    
    /**
     * Finds the next anniversary date of the given input date after today, considering leap years.
     * @param inputDate The input date for which to find the next anniversary.
     * @return The next anniversary date after today.
     */
    public static Date findNextAnniversary(Date inputDate) {
        Date today = Date.today();  // Get today's date
        Boolean isLeapDay = false;
        Integer yearsToAdd = 0;  // Initialize the years to add
        Date nextAnniversary;  // Initialize the next anniversary date
        
        // Check if the input date is a leap day
        if (inputDate.month()==2 && inputDate.day()==29){
            isLeapDay = true;
            inputDate = Date.newInstance(inputDate.year(), 2, 28);   
        }
        nextAnniversary = inputDate;
    
        // Keep adding years to the input date until the next anniversary is after today
        while (nextAnniversary <= today) {
            yearsToAdd++;
            nextAnniversary = inputDate.addYears(yearsToAdd);
        }
        return nextAnniversary;  // Return the next anniversary date
    }

}