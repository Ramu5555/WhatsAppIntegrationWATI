public class CustomMetadataUtils implements Metadata.DeployCallback {
    
    //Inteface method 
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            //Success
            System.debug('Success Result-' + result);
        } else {
            //Failed
            System.debug('Failed Result-' + result);
        }
    }
    
    //Create Custom Metadata record
    public static void createCustomMetadata(String metdataName, String label, Map<String, Object> metadataFieldValueMap){
        String recordDevName = label.replaceAll(' ', '_');
        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;
        
        for(String key : metadataFieldValueMap.keySet()){
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            cMetadataValue.Value = metadataFieldValueMap.get(key); 
            cMetadata.values.add(cMetadataValue);
        }
        
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(cMetadata);
        CustomMetadataUtils callback = new CustomMetadataUtils();
        if(!Test.isRunningTest()){
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }
    
    //Update Custom Metadata record
    public static void updateCustomMetadata(String metdataName, String recordDevName, String label, Map<String, Object> metadataFieldValueMap){
        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;
        
        for(String key : metadataFieldValueMap.keySet()){
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            cMetadataValue.Value = metadataFieldValueMap.get(key); 
            cMetadata.values.add(cMetadataValue);
        }
        
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(cMetadata);
        CustomMetadataUtils callback = new CustomMetadataUtils();
        if(!Test.isRunningTest()){
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }
    @AuraEnabled
    public static void createMetaData(String apiKey ,String urlED, String objName, String phone)
    {
        System.debug('apiKey: '+apiKey);
        String apiKey1 = apiKey.replace('Bearer ', '');
        Map<String, Object> metadataFieldValueMap = new Map<String, Object>();
        metadataFieldValueMap.put('DhruvsoftWATI__API_Key__c', apiKey1);
        metadataFieldValueMap.put('DhruvsoftWATI__End_Point_URL__c', urlED+'/api/');
        metadataFieldValueMap.put('DhruvsoftWATI__Object_Name__c', objName);
        metadataFieldValueMap.put('DhruvsoftWATI__Phone_Field__c', phone);
        CustomMetadataUtils.createCustomMetadata('DhruvsoftWATI__API_Configurations__mdt', 'WATI API Config', metadataFieldValueMap);
        
        WhatsAppSetupScreenController.createRemoteSiteSetting(urlED);
    }
    public static void createTemplateMetaData(String label,String WAParamName ,String tempBody)
    {
        System.debug('apiKey: '+WAParamName);
        Map<String, Object> metadataFieldValueMap = new Map<String, Object>();
        metadataFieldValueMap.put('DhruvsoftWATI__WA_Param_Name__c', WAParamName);
        metadataFieldValueMap.put('DhruvsoftWATI__Template_Body__c', tempBody);
        metadataFieldValueMap.put('DhruvsoftWATI__Template_Name__c',label);
        CustomMetadataUtils.createCustomMetadata('DhruvsoftWATI__Template_Param_Configuration__mdt', label+' '+WAParamName, metadataFieldValueMap);
    }
    public static void updateTemplateMetaData(String label,String WAParamName,String SFFieldName)
    {
        System.debug('apiKey: '+WAParamName);
        Map<String, Object> metadataFieldValueMap = new Map<String, Object>();
        metadataFieldValueMap.put('DhruvsoftWATI__WA_Param_Name__c', WAParamName);
        metadataFieldValueMap.put('DhruvsoftWATI__SF_Field_API_Name__c', SFFieldName);
        metadataFieldValueMap.put('DhruvsoftWATI__Template_Name__c',label);
        CustomMetadataUtils.createCustomMetadata('DhruvsoftWATI__Template_Param_Configuration__mdt', label+' '+WAParamName, metadataFieldValueMap);
    }
}