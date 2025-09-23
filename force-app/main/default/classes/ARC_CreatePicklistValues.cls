global class ARC_CreatePicklistValues implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options) {
        if (methodName.equals('PopulatePicklist')) {
            PopulatePicklist(input, outMap, options);
        }
        return true;
    }

    // Get All Relationship Types for Account when the Omniscript is compiled.
    public void PopulatePicklist(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options) {
        List < Map < String, String >> yearList = new List < Map < String, String >> ();
        Integer currentYear = System.Today().year();
        currentYear -=1;
        for(Integer i = 0 ; i<=8; i++){
            currentYear += 1;
            Map<String,String> yearOption = new Map<String,String>();
            yearOption.put('name', String.valueOf(currentYear));
            yearOption.put('value', String.valueOf(currentYear));
            yearList.add(yearOption);
        }
        outMap.put('options', yearList);
    }
}