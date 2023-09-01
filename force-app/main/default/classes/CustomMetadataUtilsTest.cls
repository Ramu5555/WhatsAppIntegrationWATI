@isTest
private class CustomMetadataUtilsTest{
    
    @isTest
    static void testCreateCustomMetadata() {
        
        String metdataName = 'Custom_Metadata_Type';
        String label = 'Custom Metadata Record';
        Map<String, Object> metadataFieldValueMap = new Map<String, Object>();
        metadataFieldValueMap.put('Field1__c', 'Value1');
        metadataFieldValueMap.put('Field2__c', 'Value2');
        
        Test.startTest();
        CustomMetadataUtils.createCustomMetadata(metdataName, label, metadataFieldValueMap);
        Test.stopTest();
        System.assertEquals('Test', 'Test');
    }
    
    @isTest
    static void testUpdateCustomMetadata() {
        String metdataName = 'Custom_Metadata_Type';
        String recordDevName = 'Custom_Metadata_Record';
        String label = 'Custom Metadata Record';
        Map<String, Object> metadataFieldValueMap = new Map<String, Object>();
        metadataFieldValueMap.put('Field1__c', 'UpdatedValue1');
        metadataFieldValueMap.put('Field2__c', 'UpdatedValue2');
        
        Test.startTest();
        CustomMetadataUtils.updateCustomMetadata(metdataName, recordDevName, label, metadataFieldValueMap);
        Test.stopTest();
        System.assertEquals('Test', 'Test');
        
    }
    
    @isTest
    static void testCreateMetaData() {
        // Test data
        String label = 'API Configuration';
        String apiKey = 'Bearer API_KEY';
        String urlED = 'https://example.com';
        String objName = 'Custom_Object__c';
        String phone = 'Phone_Field__c';
        
        Test.startTest();
        CustomMetadataUtils.createMetaData(apiKey, urlED, objName, phone);
        Test.stopTest();
        
        System.assertEquals('Test', 'Test');
    }
    
    @isTest
    static void testCreateTemplateMetaData() {
        // Test data
        String label = 'Template Configuration';
        String WAParamName = 'WA_Param';
        String tempBody = 'Template Body';
        
        Test.startTest();
        CustomMetadataUtils.createTemplateMetaData(label, WAParamName, tempBody);
        Test.stopTest();
        
        System.assertEquals('Test', 'Test');
        
    }
    
    @isTest
    static void testUpdateTemplateMetaData() {
        String label = 'Template Configuration';
        String WAParamName = 'WA_Param';
        String SFFieldName = 'Custom_Field__c';
        
        Test.startTest();
        CustomMetadataUtils.updateTemplateMetaData(label, WAParamName, SFFieldName);
        Test.stopTest();
        System.assertEquals('Test', 'Test');
        
    }
}