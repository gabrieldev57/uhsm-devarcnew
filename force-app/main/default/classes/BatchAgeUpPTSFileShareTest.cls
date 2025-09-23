@isTest
public class BatchAgeUpPTSFileShareTest {
    
    
    @isTest
    static void invokeMethodDataTest(){
		
        //Create a census with two members
        List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(2);
        censMemb[0].ARC_ActiveMember__c = true;
        censMemb[1].ARC_ActiveMember__c = true;
        censMemb[1].Name = 'censmem1';
        censMemb[0].vlocity_ins__RelatedCensusMemberId__c = censMemb[1].id;
        update censMemb;
        system.debug('BatchAgeUpPTSFileShare - censMemb[0].vlocity_ins__RelatedCensusMemberId__c' + censMemb[0].vlocity_ins__RelatedCensusMemberId__c);
        
        //create a second census and a third census member
        List<vlocity_ins__GroupCensusMember__c> censMemb3 = ARC_TestUtility.createTestCensusMember(1);
        censMemb3[0].ARC_ActiveMember__c = true;
		update censMemb3;
        
        
        List<Contract> cont = ARC_TestUtility.createContractsAA(2);
        insert cont;        
		cont[0].vlocity_ins__EnrollmentCensusId__c =  censMemb[0].vlocity_ins__CensusId__c;
        cont[0].Status = 'Activated';
		cont[1].vlocity_ins__EnrollmentCensusId__c =  censMemb3[0].vlocity_ins__CensusId__c;
        cont[1].Status = 'Activated';
        update cont;
        	
        Ages_Up__c agesUp = new Ages_Up__c();
        Date birthDate = Date.newInstance(system.today().year()-40,
                                                system.today().month(), 
                                                system.today().day()).adddays(
                                                Integer.valueof(System.Label.daysBefore)
                                                );
        
        agesUp.AgesUp_Birth_Date__c=birthDate;
        agesUp.Draft_Date__c = system.today()+10;
        agesUp.Contract__c=cont[0].id;
        insert agesUp;
        
        Ages_Up__c agesUp2 = new Ages_Up__c();
        agesUp2.AgesUp_Birth_Date__c=birthDate;
        agesUp2.Draft_Date__c = system.today()+10;
        agesUp2.Contract__c=cont[1].id;
        insert agesUp2;
       
        test.startTest();
        BatchAgeUpPTSFileShare b = new BatchAgeUpPTSFileShare();
        database.executeBatch(b);
        test.stopTest();
    }
    
    static testMethod void testSchedulable() {        
         test.starttest();
         BatchAgeUpPTSFileShare schedJob = new BatchAgeUpPTSFileShare ();   
         String chron = '0 0 23 * * ?';        
         system.schedule('Test Sched - BatchAgeUpPTSFileShare', chron, schedJob);
         test.stopTest();
    }

}