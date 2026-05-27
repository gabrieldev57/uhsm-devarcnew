public class ARC_PriceCalculation {
    private List<PlanPricingInput> planInputs;
    
    public ARC_PriceCalculation(List<PlanPricingInput> inputs) {
        this.planInputs = inputs;
    }
    
    public List<PlanPricingResult> calculatePrices() {
        List<PlanPricingResult> results = new List<PlanPricingResult>();
        for (PlanPricingInput input : planInputs) {
            PlanPricingResult result = calculatePlanPrice(input);
            results.add(result);
        }
        return results;
    }
    
    private PlanPricingResult calculatePlanPrice(PlanPricingInput input) {

        PlanPricingResult result = new PlanPricingResult();
        result.productId = input.productId;
        result.planId = input.planId;
        result.contractId = input.contractId;  // Add this line
        result.priceBeforeAgeUp = input.priceBeforeAgeUp;  // Add this line
        result.plan = input.plan;  // Add this line

        try {
            Map<String, Object> inputMap = new Map<String, Object>();
            Map<String, Object> outMap = new Map<String, Object>();
            Map<String, Object> options = new Map<String, Object>();
            
            inputMap.put('userInputs', input.userInputs);
            options.put('whereClause', 'Id = \'' + input.productId + '\'');
            
            Type classType = Type.forName('vlocity_ins', 'InsProductService');
            vlocity_ins.VlocityOpenInterface2 obj = (vlocity_ins.VlocityOpenInterface2) classType.newInstance();
            obj.invokeMethod('getRatedProducts', inputMap, outMap, options);
            
            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(outMap.get('result')));
            List<Object> records = (List<Object>) JSON.deserializeUntyped(JSON.serialize(resultMap.get('records')));
            if (!records.isEmpty()) {
                Map<String, Object> record = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(records[0]));
                Map<String, Object> fields = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(record.get('fields')));
                
                if (fields.containsKey('Price')) {
                    result.price = Decimal.valueOf(String.valueOf(fields.get('Price')));
                    result.success = true;
                } else {
                    result.success = false;
                    result.errorMessage = 'Price field not found in the response';
                }
            } else {
                result.success = false;
                result.errorMessage = 'No records returned from getRatedProducts';
            }
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error calculating price: ' + e.getMessage();
        }
        
        return result;
    }
    
        public class PlanPricingInput {
        public String planId;
        public String productId;
        public String contractId;
        public Decimal priceBeforeAgeUp;
        public List<Map<String, Object>> userInputs;
        public vlocity_ins__ContractLineItem__c plan; // not required
    }
    
    public class PlanPricingResult {
        public String planId;
        public String productId;
        public String contractId;
        public String errorMessage;
        public Decimal priceBeforeAgeUp;
        public Decimal price;
        public Boolean success;
        public vlocity_ins__ContractLineItem__c plan;
    }





}