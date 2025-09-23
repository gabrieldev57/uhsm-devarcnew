public without sharing class ARC_DocusignEFTFormCalloutBatch implements Database.Batchable<Id>, Database.AllowsCallouts {

    private List<Id> case_ids_to_send_eft_form = new List<Id>();

    public ARC_DocusignEFTFormCalloutBatch(List<Id> case_ids_to_send_eft_form) {
        this.case_ids_to_send_eft_form = case_ids_to_send_eft_form;
    }

    public Iterable<Id> start(Database.BatchableContext bc){ 
        return case_ids_to_send_eft_form; 
    }

    public void execute(Database.BatchableContext info, List<Id> case_ids){
        ARC_DocuSignEFTForm.flowActionSendEFTFormEnvelope(case_ids);
    }

    public void finish(Database.BatchableContext bc){} 

}