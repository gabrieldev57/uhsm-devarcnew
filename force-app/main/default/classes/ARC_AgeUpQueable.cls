public with sharing class ARC_AgeUpQueable implements Queueable {
    private Set<Id> contractIds;
    public ARC_AgeUpQueable(Set<Id> contractIds) {
        this.contractIds = contractIds;
    }
    public void execute(QueueableContext context) {
        ARC_AgeUp.calculateAgeUp(this.contractIds);
    }
}