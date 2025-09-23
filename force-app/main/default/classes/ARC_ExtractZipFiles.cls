public class ARC_ExtractZipFiles {
    @AuraEnabled(cacheable=true)
    public static List<string> getImagesList(){
        
        StaticResource staticRes = [SELECT Body FROM StaticResource WHERE Name = 'ARC_Logos'];
        Zippex minionsDemoZip = new Zippex(staticRes.Body);
        System.debug(minionsDemoZip);
        List<String> imgstr = new List<String>();
        for(String imgFileName : minionsDemoZip.getFileNames()){
            if(imgFileName.endsWith('.png') || imgFileName.endsWith('.svg')){
                imgstr.add(imgFileName);
            }
        }
        return imgstr;
    }
}