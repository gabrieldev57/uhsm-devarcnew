public without sharing class ARC_CounterXMLFile {
    public static String generateCounter() {
        String printString = '';
        ARC_XMLCounter__c xmlCounter = ARC_XMLCounter__c.getInstance('ZelisXML');
        // List<String> counterArray = new List <String>{'00','00'};
        if (Test.isRunningTest()) {
            xmlCounter = new ARC_XMLCounter__c();
            xmlCounter.ARC_Date__c = Date.today();
            xmlCounter.ARC_Counter__c = '00.00';
        }
        System.debug('xmlCounter.ARC_Date__c: '+ xmlCounter.ARC_Date__c);
        System.debug('Today: '+ Date.today());
        if(xmlCounter.ARC_Date__c == Date.today()){
            System.debug(xmlCounter.ARC_Counter__c);
            String [] counterArray = xmlCounter.ARC_Counter__c.split('\\.');
            System.debug(counterArray);
            Integer secondValue= Integer.valueOf(counterArray[1]);
            secondValue++;
            List<Integer> counter = new List<Integer>{secondValue, Integer.valueOf(counterArray[0])};//00.00 -> 00.01-> 00.09 -> 00
            System.debug('counter '+counter);
            for ( Integer o = counter.size() - 1; o >= 0 ; o-- ) {
                System.debug('o '+o);
                if ( counter[o] == 10 ) {
                    // A value
                    counter[o] = 65;
                }
                // Z value
                if ( counter[o] == 91 ) { 
                    counter[o] = 0;
                    if ( o == counter.size() - 1 ) {
                        counter.add(1);
                        printString += '1';
                    } else {
                        counter[o+1] = counter[o+1] + 1;
                        if ( counter[o+1] < 10 ) {
                            printString += String.valueOf(counter[o+1]);
                        } else {
                            if(counter[o+1] == 10)  counter[o+1] = 65;
                            printString += String.fromCharArray(new List<Integer>{counter[o+1]});
                        }
                        if ( printString.length() > o ) {
                            printString = printString.split('').remove(o+1);
                        }
                    }
                }
                
                if ( counter[o] < 10 ) {
                    printString += String.valueOf(counter[o]);
                } else {
                    printString += String.fromCharArray(new List<Integer>{counter[o]});
                } 
            }
            counterArray = new List<String>{String.valueOf(counter[1]), String.valueOf(counter[0])};
            xmlCounter.ARC_Counter__c = String.join(counterArray,'.');
        }
        else{
            xmlCounter.ARC_Counter__c='00.00';
            xmlCounter.ARC_Date__c = Date.today();
            printString='00';
        }
        System.debug(printString);

        if (Test.isRunningTest() == false) {
            update xmlCounter;
        }

    return printString;
    }

    
}