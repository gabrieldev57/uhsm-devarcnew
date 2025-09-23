public class ARC_AccountBirthdateComparator implements Comparator<Account> {
    private Date targetBirthdate;

    // Constructor to initialize the comparator with a target birthdate
    public ARC_AccountBirthdateComparator(Date targetBirthdate) {
        this.targetBirthdate = targetBirthdate;
    }

    // Compare method to order accounts by their PersonBirthdate's closeness to the target birthdate
    public Integer compare(Account a1, Account a2) {
        // Handle null values gracefully
        if (a1.PersonBirthdate == null && a2.PersonBirthdate == null) {
            return 0;
        } else if (a1.PersonBirthdate == null) {
            return 1;
        } else if (a2.PersonBirthdate == null) {
            return -1;
        }

        // Calculate the difference in days between each account's birthdate and the target birthdate
        Integer diff1 = Math.abs(a1.PersonBirthdate.daysBetween(targetBirthdate));
        Integer diff2 = Math.abs(a2.PersonBirthdate.daysBetween(targetBirthdate));

        // Return the comparison result
        if (diff1 > diff2) {
            return 1;
        } else if (diff2 > diff1){
            return -1;
        } else{
            return 0;
        }
    }
}