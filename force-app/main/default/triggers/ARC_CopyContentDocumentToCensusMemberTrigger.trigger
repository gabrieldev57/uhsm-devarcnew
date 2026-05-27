trigger ARC_CopyContentDocumentToCensusMemberTrigger on ContentDocumentLink (before insert, before update, after insert) {
  if(trigger.isBefore && trigger.isInsert) {
    ARC_CopyContentDocumentTriggerHandler.onBefore(Trigger.New);
  }

  if(trigger.isBefore && trigger.isUpdate) {
     ARC_CopyContentDocumentTriggerHandler.onBefore(Trigger.New);
  }

  if(trigger.isAfter && trigger.isInsert) {
    ARC_CopyContentDocumentTriggerHandler.onAfter(Trigger.New);
  }

}