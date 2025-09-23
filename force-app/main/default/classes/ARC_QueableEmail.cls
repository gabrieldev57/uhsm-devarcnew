public with sharing class ARC_QueableEmail implements Queueable{
    private Map<String,Object> inputMap = new Map<String,Object>();
    private Integer emailIdentifier;

    public ARC_QueableEmail(Map<String,Object> input, Integer identifier) {
        this.inputMap = input;
        this.emailIdentifier = identifier;
    }

    public void execute(QueueableContext context) {
        System.debug('queable email');
        // sendEmail(JSON.serialize(this.inputMap), this.emailIdentifier);
        // 
        try{
        	ARC_Emails.invokeMethod('email_'+emailIdentifier, this.inputMap, new Map<String, Object>(), new Map<String, Object>());
        }catch(Exception e){
            System.debug(e);
			ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ARC_TransactionHandler.email_'+emailIdentifier,String.valueOf(this.inputMap));
        }
    }



}