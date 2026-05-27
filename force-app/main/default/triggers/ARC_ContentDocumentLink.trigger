trigger ARC_ContentDocumentLink on ContentDocumentLink (after insert) {
    ARC_InvoiceEmailHandler.handleContentDocumentLinkInsert(Trigger.new);
    ARC_ContentDocumentLinkHandler.handleAfterInsert(Trigger.new);
}