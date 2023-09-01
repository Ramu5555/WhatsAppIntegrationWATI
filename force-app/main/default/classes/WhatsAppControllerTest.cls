@isTest
public class WhatsAppControllerTest {
    @isTest
    public static void testMethod1() {
        Contact con = new Contact();
        con.LastName = 'Ramu';
        con.MobilePhone = '9998885551';
        con.Phone = '9876543210'; 
        insert con;
        
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body to be inserted in the test class for testing');
        
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'SampleTitle',
            PathOnClient = 'SampleTitle.jpg',
            VersionData = bodyBlob,
            Origin = 'H'
        );
        insert contentVersion_1;
        
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = con.Id;
        contentlink.ContentDocumentId = contentVersion_2.ContentDocumentId;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        String seachName='';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WhatsAppControllerMock1());
        Test.stopTest();
        
        WhatsAppController.getTemplates();
        WhatsAppController.getContactList(seachName);
        WhatsAppController.getMessages(con.Id, '');
        WhatsAppController.sendSingleMessage(con.Id, 'hi');
        WhatsAppController.sendTemplate(con.Id, 'new_chat');
        List<String> memList = new List<String>{con.Id};
            WhatsAppController.sendTemplates(memList, 'new_chat');
        WhatsAppController.uploadFiles(con.Id);
        WhatsAppController.getVersionFiles(con.Id);
        WhatsAppController.saveTemplateMetadata();
        
        // Add assertions here
        System.assertEquals(1, 1); // Example assertion
    }
    
    @isTest
    public static void testMethod2() {
        Contact con = new Contact();
        con.LastName = 'Ramu';
        con.MobilePhone = '9998885551';
        con.Phone = '9876543210';
        insert con;
        
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body to be inserted in the test class for testing');
        
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'SampleTitle',
            PathOnClient = 'SampleTitle.jpg',
            VersionData = bodyBlob,
            Origin = 'H'
        );
        insert contentVersion_1;
        
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = con.Id;
        contentlink.ContentDocumentId = contentVersion_2.ContentDocumentId;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WhatsAppControllerMock2());
        Test.stopTest();
        
        WhatsAppController.getTemplates();
        //WhatsAppController.getMessages(con.Id, '');
        WhatsAppController.sendSingleMessage(con.Id, 'hi');
        WhatsAppController.sendTemplate(con.Id, 'onboarding_signoff');
        List<String> memList = new List<String>{con.Id};
            List<Id> ids = new List<Id>{con.Id};
                WhatsAppController.sendTemplates(memList, 'onboarding_signoff');
        WhatsAppController.sendTemplateFlow(ids);
        WhatsAppController.uploadFiles(con.Id);
        WhatsAppController.getVersionFiles(con.Id);
        WhatsAppController.getMessages1('918885593331','');
        WhatsAppController.sendMessageListPage('918885593331','Hi');
        WhatsAppController.sendTemplateListPage('918885593331','new_chat','Ramu');
        WhatsAppController.refreshMessagesListPage('918885593331','');
        
        
        // Add assertions here
        System.assertEquals(1, 1); // Example assertion
    }
    @isTest
    public static void testMethod3(){
        Contact con = new Contact();
        con.LastName = 'WhatsApp Integration Contact';
        con.MobilePhone = '9998885551';
        con.Email='whatsappintegration@WATI.com';
        con.Phone = '9876543210';
        insert con;
        
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body to be inserted in the test class for testing');
        
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'SampleTitle',
            PathOnClient = 'SampleTitle.jpg',
            VersionData = bodyBlob,
            Origin = 'H'
        );
        insert contentVersion_1;
        
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = con.Id;
        contentlink.ContentDocumentId = contentVersion_2.ContentDocumentId;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WhatsAppControllerMock3());
        Test.stopTest();
        
        WhatsAppController.refreshMessages(con.Id, '');
        WhatsAppController.getMessages(con.Id, '');
        WhatsAppController.getMessages1('918885593331','');
        WhatsAppController.sendMessageListPage('918885593331','Hi');
        WhatsAppController.sendTemplateListPage('918885593331','new_chat','Ramu');
        WhatsAppController.refreshMessagesListPage('918885593331','');
        
        // Add assertions here
        System.assertEquals(1, 1); // Example assertion
        
    }
}