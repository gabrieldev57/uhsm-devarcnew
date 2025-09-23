@isTest
public class ARC_ExtractZipFilesTest {

    @isTest 
    static void testgetImagesList(){ 
        List<StaticResource> srList = ARC_TestUtility.createTestStaticResource(5);
        System.debug(srList);
        StaticResource testSR = srList[0];
        Zippex demoZip = new Zippex(testSR.Body);
        List<String> imgstr = new List<String>();
        for(String imgFileName : demoZip.getFileNames()){
            if(imgFileName.endsWith('.png') || imgFileName.endsWith('.svg')){
                imgstr.add(imgFileName);
            }
        }
        List<string> imgStrings = ARC_ExtractZipFiles.getImagesList();
        System.assertEquals(imgstr, imgStrings);
    }


}