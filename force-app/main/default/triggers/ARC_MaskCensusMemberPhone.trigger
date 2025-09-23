trigger ARC_MaskCensusMemberPhone on vlocity_ins__GroupCensusMember__c (before insert, before update) {
  sObjectField[] phoneFields = new sObjectField[] {
      vlocity_ins__GroupCensusMember__c.ARC_Phone__c
  };
  for(vlocity_ins__GroupCensusMember__c record: Trigger.new) {
    for(sObjectField field: phoneFields) {
      String phoneNumber = (String)record.get(phoneFields[0]);
      if(phoneNumber != null && phoneNumber != '' && phoneNumber.substring(0,2) != '+1' && phoneNumber.length() == 10) {
          System.debug('phoneNumber 10');
          System.debug(phoneNumber);
          String newPhoneNumber = '+1' + phoneNumber;
          System.debug('newPhoneNumber 10');
          System.debug(newPhoneNumber);
          record.put(field, newPhoneNumber);
      } 
      // else if (phoneNumber != null && phoneNumber != '' && phoneNumber.substring(0,2) != '+1' && phoneNumber.length() == 11) {
      //   System.debug('phoneNumber 11');
      //     System.debug(phoneNumber);
      //     String newPhoneNumber = '+' + phoneNumber;
      //     System.debug('newPhoneNumber 11');
      //     System.debug(newPhoneNumber);
      //     record.put(field, newPhoneNumber);
      // }
      // else if (phoneNumber != null && phoneNumber != '' && phoneNumber.length() == 14){
      //   System.debug('phoneNumber 14');
      //   System.debug(phoneNumber);
      //   String newPhoneNumber = '+1' + phoneNumber.substring(1, 4) + phoneNumber.substring(6, 9) + phoneNumber.substring(11, 14);
      //   System.debug('newPhoneNumber 14');
      //     System.debug(newPhoneNumber);
      //     record.put(field, newPhoneNumber);
      // } else if (phoneNumber != null && phoneNumber != '' && phoneNumber.length() == 15){
      //   System.debug('phoneNumber 15');
      //   System.debug(phoneNumber);
      //   String newPhoneNumber = '+' +phoneNumber.substring(0, 1) + phoneNumber.substring(2, 5) + phoneNumber.substring(7, 10) + phoneNumber.substring(12, 15);
      //   System.debug('newPhoneNumber 15');
      //     System.debug(newPhoneNumber);
      //     record.put(field, newPhoneNumber);
      // }
    }
  }

  System.debug('MaskPhone trigger finished');
}