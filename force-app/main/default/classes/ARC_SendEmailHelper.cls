public class ARC_SendEmailHelper {
    @AuraEnabled
    public static void sendEmail(String Sender , String reciever , EmailTemplate Template, String eCC, Id objectId, OrgWideEmailAddress fromAddress) {
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        String[] sendingTo = new List<String>();
        String[] CCemail = new List<String>();
        if (reciever.contains(';')) {
            sendingTo = reciever.split(';');
        } else {
            sendingTo.add(reciever);
        }
        if (eCC != null) {
            if (eCC.contains(';')) {
                CCemail = eCC.split(';');
            } else {
                CCemail.add(eCC);
            }
        }

        System.debug('RECIEVER: ' + sendingTo);
        System.debug('CC EMAIL: ' + CCemail);
        Schema.SObjectType sObjType = objectId.getSobjectType();
        String body;
        if (Template.HtmlValue != null) {
            body = replaceMergeFields(Template.HtmlValue, objectId);
        } else if (Template.Markup != null) {
            body = Template.Markup;
        } else {
            body = Template.Body;
        }
        System.debug('BODY = ' + body);
        String subject = Template.Subject;
        semail.setOrgWideEmailAddressId(fromAddress.Id); 
        semail.setToAddresses(sendingTo); 
        semail.setSubject(subject); 
        semail.setHtmlBody(body);
        //Id AccId = '0035e00000Q0NJ0AAN';
        //semail.setTargetObjectId(AccId);
        //semail.setTemplateId(Template.Id);
        //semail.setWhatId(objectId);

        //semail.setSenderDisplayName(Sender);
        if (CCemail.size() > 0) {
            semail.setCcAddresses(CCemail);
        }
        System.debug('Email successfully sent');
        // Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
    }

    private static Map<String, String> solveBrackets(String expression) {
        List<String> tempArray = expression.split('');
        Integer i=0;
        List<String> newExpressions = new List<String>();
        Map<String, String> mergeMap = new Map<String, String>();
        while (i<tempArray.size()) {
            if (tempArray[i] == '{') {
                Integer endIndex = i + findClosingBrackets(expression.substring(i));
                String newExp = expression.substring(i, endIndex+1);
                newExpressions.add(newExp);
                i=endIndex+1;
            } else {
                i++;
            }
        }
        for (String s : newExpressions) {
            String noBrackets = s.substringBetween('{!','}');
            mergeMap.put(s,noBrackets);
        }
        return mergeMap;
    }

    private static Integer findClosingBrackets(String expression) {
        List<Integer> bracketPositions = new List<Integer>();
        Integer index;
        List<String> tempArray = expression.split('');
        for (Integer i = 0; i<tempArray.size(); i++) {    
            if (tempArray[i] == '{') {
                bracketPositions.add(i);
            } else if (tempArray[i] == '}') {
                bracketPositions.remove(bracketPositions.size()-1);
                if (bracketPositions.size() == 0) {
                    index = i;
                    break;
                }
            }
        }  
        return index;
    }

    public static String replaceMergeFields(String expression, Id ObjectId) {
        Map<String, String> mergeFields = ARC_SendEmailHelper.solveBrackets(expression);
        System.debug('mergeFields' + mergeFields);
        Schema.SObjectType sObjectType = ObjectId.getSobjectType();
        String obj = sObjectType.getDescribe().getName();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SobjectType sObj = gd.get(obj);

        List<String> mergeValues = new List<String>();
        for (String m : mergeFields.keySet()) {
            String value = mergeFields.get(m);
            mergeValues.add(value);
        }
        System.debug('mergeValues' + mergeValues);
        List<String> listForQuery = new List<String>();
        String querySelect = 'SELECT Id, ';
        String queryFields = '';
        String queryFrom = ' FROM '+sObj+' WHERE Id = :ObjectId';
        for (String value : mergeValues) {
            List<String> splitValue = value.split('\\.');
            if (splitValue[0] == obj) {
                String mergeField = splitValue[1];
                listForQuery.add(mergeField);
            } else {
                listForQuery.add(value);
                 
            }
        }
        for (String value : listForQuery) {
            if (!queryFields.containsIgnoreCase(value)) {
                queryFields = queryFields + value + ', ';
            }
        }
        System.debug('queryFields' + queryFields);
        String objFields = queryFields.substring(0, queryFields.length()-2);
        List<SObject> objQuery = Database.query(querySelect + objFields + queryFrom);
        Map<String, String> finalMap = new Map<String, String>();
        for (String value : mergeValues) {
            String valueConcat = '{!' + value + '}';
            List<String> splitValue = value.split('\\.');
             System.debug('splitValueIvan' + splitValue );
            String mergeField;
            if (splitValue[0].contains(obj)) {
                mergeField = (String)objQuery[0].get(splitValue[1].trim());
            } else if (splitValue.size() == 2) {
				mergeField = (String)objQuery[0].getSObject(splitValue[0].trim()).get(splitValue[1].trim());
            }
            System.debug('mergeField1: ' + mergeField);
            if (mergeField == null) {
                mergeField = '';
            }
            System.debug('mergeField2: ' + mergeField);
            finalMap.put(valueConcat, mergeField);
        }
        for (String key : finalMap.keySet()) {
            expression = expression.replace(key, finalMap.get(key));
        }
        return expression;
    }

    
}