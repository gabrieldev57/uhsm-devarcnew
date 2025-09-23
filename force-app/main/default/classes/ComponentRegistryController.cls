public with sharing class ComponentRegistryController {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAvailableComponents() {
        Map<String, String> componentMap = new Map<String, String>();
        
        // Add your components here
        componentMap.put('component1', 'c/component1');
        componentMap.put('component2', 'c/component2');
        // Add more components as needed
        
        return componentMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean isComponentAvailable(String componentName) {
        Map<String, String> components = getAvailableComponents();
        return components.containsKey(componentName);
    }
}