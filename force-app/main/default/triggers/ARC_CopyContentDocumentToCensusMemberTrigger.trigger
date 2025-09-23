trigger ARC_CopyContentDocumentToCensusMemberTrigger on ContentDocumentLink (before insert, before update, after insert) {
  
  if (UserInfo.getUserType() == 'Guest') {
    System.debug('Here Guest trigger ');
    return; 
  }
  else{
    if(trigger.isBefore && trigger.isInsert) {
      System.debug('Trigger isInsert heree');
      ARC_CopyContentDocumentTriggerHandler.onBefore(Trigger.New);
    }
  
    if(trigger.isBefore && trigger.isUpdate) {
      System.debug('Trigger isUpdate heree');
      //ARC_CopyContentDocumentTriggerHandler.onBefore(Trigger.New);
    }
  
    if(trigger.isAfter && trigger.isInsert) {
      ARC_CopyContentDocumentTriggerHandler.onAfter(Trigger.New);
    }
  }
}