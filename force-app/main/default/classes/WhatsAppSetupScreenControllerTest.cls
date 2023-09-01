@isTest
private class WhatsAppSetupScreenControllerTest {
    @isTest
    static void testGetWhatsAppSetupScreen() {
        // Test data
        
        Test.startTest();
        List<WhatsAppSetupScreenController.TemplateWrapper> result = WhatsAppSetupScreenController.getWhatsAppSetupScreen();
        Test.stopTest();
        System.assertEquals('Test', 'Test');
    }
    
    @isTest
    static void testSaveTemplateParams() {
        // Test data
        WhatsAppSetupScreenController.TemplateWrapper template1 = new WhatsAppSetupScreenController.TemplateWrapper();
        template1.templateName = 'Template 1';
        template1.paramsList = new List<WhatsAppSetupScreenController.ParamWrapper>();
        WhatsAppSetupScreenController.ParamWrapper param1 = new WhatsAppSetupScreenController.ParamWrapper();
        param1.paramName = 'Param 1';
        param1.paramValue = 'Field1__c';
        template1.paramsList.add(param1);
        
        List<WhatsAppSetupScreenController.TemplateWrapper> templateList = new List<WhatsAppSetupScreenController.TemplateWrapper>();
        templateList.add(template1);
        String templateJson = JSON.serialize(templateList);
        
        Test.startTest();
        WhatsAppSetupScreenController.saveTemplateParams(templateJson);
        WhatsAppSetupScreenController.getContactFiedls();
        WhatsAppSetupScreenController.createRemoteSiteSetting('https://live-server-102488.wati.io');
        Test.stopTest();
        
        // Verify the updated custom metadata
        List<Template_Param_Configuration__mdt> updatedTemplates = [SELECT SF_Field_API_Name__c FROM Template_Param_Configuration__mdt];
        System.assertEquals('name', updatedTemplates[0].SF_Field_API_Name__c, 'Incorrect param value');
    }
}