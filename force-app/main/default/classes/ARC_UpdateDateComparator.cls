public class ARC_UpdateDateComparator implements Comparator<Map<String,String>> {
    public Integer compare(Map<String,String> map1, Map<String,String> map2) {
        String updatedDate1 = map1.get('UpdateDate');
        String updatedDate2 = map2.get('UpdateDate');

        Datetime dateTime1 = Datetime.valueOf(updatedDate1);
        Datetime dateTime2 = Datetime.valueOf(updatedDate2);
        
        return dateTime2 > dateTime1 ? 1 : -1;
    }
}