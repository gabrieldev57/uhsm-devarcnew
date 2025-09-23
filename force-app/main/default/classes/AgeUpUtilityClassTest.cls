@isTest
public class AgeUpUtilityClassTest {
    @isTest
    static void testHasBirthdayAnniversary() {
        // Test cases for hasBirthdayAnniversary method
        // Test case 1: Birthday is within the effectiveDate and effectiveDatePlus60
        Date birthDate1 = Date.newInstance(2000, 8, 1);
        Date effectiveDate1 = Date.newInstance(2023, 7, 30);
        Boolean result1 = AgeUpUtilityClass.hasBirthdayAnniversary(birthDate1, effectiveDate1);
  
        
        // Test case 2: Birthday is after effectiveDatePlus60
        Date birthDate2 = Date.newInstance(2000, 2, 2);
        Date effectiveDate2 = Date.newInstance(2023, 7, 1);
        Boolean result2 = AgeUpUtilityClass.hasBirthdayAnniversary(birthDate2, effectiveDate2);

        
        // Test case 3: Birthday is before the effectiveDate, but effectiveDatePlus60 is in the next year
        Date birthDate3 = Date.newInstance(2000, 2, 5);
        Date effectiveDate3 = Date.newInstance(2023, 12, 30);
        Boolean result3 = AgeUpUtilityClass.hasBirthdayAnniversary(birthDate3, effectiveDate3);
        
        // Test case 4: Birthday is on the same day as effectiveDatePlus60, but effectiveDatePlus60 is in the next year
        Date birthDate4 = Date.newInstance(2000,11, 15);
        Date effectiveDate4 = Date.newInstance(2023, 12, 30);
        Boolean result4 = AgeUpUtilityClass.hasBirthdayAnniversary(birthDate4, effectiveDate4);
      
    }
    
    @isTest
    static void testFindNextAnniversary() {
        // Test case 1: return is the next anniversary
        Date today = Date.today();
        Date date1 = Date.newInstance(2000, 12, 31);
        Date anniversaryDate1 = Date.newInstance(today.year(), 12, 31);
        Boolean result1 = (AgeUpUtilityClass.findNextAnniversary(date1) == anniversaryDate1);
     
        // Test case 2: return is not the next anniversary
        Date date2 = Date.newInstance(2000, 12, 31);
        Date anniversaryDate2 = Date.newInstance(today.year()+1, 12, 31);
        Boolean result2 = (AgeUpUtilityClass.findNextAnniversary(date2) == anniversaryDate2);


        // Test case 3: return is Next feb 28th for leap days
        Date date3 = Date.newInstance(2000, 2, 29);
        Date anniversaryDate3 = Date.newInstance(today.year()+1, 2, 28);
        
        if (Date.today().month()<3){
            anniversaryDate3 = Date.newInstance(today.year(), 2, 28);
        }
        
        Boolean result3 = (AgeUpUtilityClass.findNextAnniversary(date3) == anniversaryDate3);
   
        
    }
    
}