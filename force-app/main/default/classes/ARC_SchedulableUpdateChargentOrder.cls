public with sharing class ARC_SchedulableUpdateChargentOrder implements Schedulable {

    public List<ChargentOrders__ChargentOrder__c> ordersToProcess= new List<ChargentOrders__ChargentOrder__c>();

    public ARC_SchedulableUpdateChargentOrder(List<ChargentOrders__ChargentOrder__c> orders){
        this.ordersToProcess = orders;
    }

    public void execute(System.SchedulableContext sc){
       System.debug('Orders to process: '+this.ordersToProcess.size());
       update this.ordersToProcess;
       for(ChargentOrders__ChargentOrder__c order : this.ordersToProcess){
           System.debug('order.ChargentOrders__Subtotal__c : '+order.ChargentOrders__Subtotal__c);
           System.debug('order.ChargentOrders__Charge_Amount__c : '+order.ChargentOrders__Charge_Amount__c);
       }
        System.abortJob(sc.getTriggerId());
    }
}