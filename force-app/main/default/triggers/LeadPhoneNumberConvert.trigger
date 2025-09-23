trigger LeadPhoneNumberConvert on Lead (before insert,before update) {
/* UHSM-130
 * When a Lead is created or Updated
 * Convert text entered into the Lead.Phone field
 * from various common 10 and 11 digit formarts into E.164 format
 * ignoring phone numbers less than 10 digits, more than 11 digits,
 * or 11 digit where the first digit is not a 1 (international) */
    
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)                          ){
        for(Lead leadRec : trigger.New)
        {
           	String phonee164 = String.valueOf(leadRec.Phone);
            System.debug('phonee164 ======> '+ phonee164);
            if(phonee164 !=null && phonee164.substring(0,2) !='+1' && phonee164.length() >= 10)
            {   
                phonee164 = phonee164.replaceAll('[^0-9\\s+]', '');
            	phonee164 = phonee164.replace(' ', '');
            	phonee164 = phonee164.replace('+', '');
            	System.debug('removeNonNumber ======> '+ phonee164);
                if(phonee164.length() == 10 ){
                    System.debug('phone length ======>10 ');
                	leadRec.Phone = '+1' +  phonee164;
                	System.debug('newphonee164 ======> '+ leadRec.Phone);  
                }
                else if(phonee164.length() == 11 && phonee164.substring(0,1) =='1' ){
                    System.debug('phone length ======>11 ');
                    leadRec.Phone = '+' +  phonee164;
                	System.debug('newphonee164 ======> '+ leadRec.Phone);  
                }
            
             }
             System.debug('-------> end trigger');
        }
    }
}